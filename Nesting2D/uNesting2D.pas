unit uNesting2D;

{ ============================================================================
  Form del modulo NESTING 2D (encaje de piezas irregulares en una planxa).

  Permite:
    - Definir la planxa (ancho x alto) y parametros de corte (kerf, veta, paso).
    - Anadir piezas: formas parametricas (rectangulo, triangulo, circulo
      aproximado, L, T) o un poligono libre por vertices (X/Y).
    - Calcular el encaje (motor de uNesting2DEngine).
    - Ver el resultado dibujado (GDI+, doble buffer) con las planxas y piezas.
    - Ver metricas de aprovechamiento.
    - Exportar el plano a PNG y el listado de colocaciones a CSV.

  Entrada: se abre modal via ShowNesting2D(AOwner).
  ============================================================================ }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Math, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  Winapi.GDIPOBJ, Winapi.GDIPAPI,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxStyles, cxClasses, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxButtons, cxTextEdit, cxSpinEdit,
  cxMaskEdit, cxDropDownEdit,
  uNesting2DTypes, uNesting2DEngine;

type
  { Modo de la herramienta: True-Shape (formas irregulares) o Rectangular (solo
    rectangulos). Cambia el catalogo de formas ofrecido y el titulo. }
  TNestingMode = (nmTrueShape, nmRectangular);

  TfrmNesting2D = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlLeft: TPanel;
    pnlCanvas: TPanel;
    pbCanvas: TPaintBox;
    pnlMetrics: TPanel;
    lblMetrics: TLabel;
    // --- parametros planxa ---
    lblAncho: TLabel;
    edAncho: TcxSpinEdit;
    lblAlto: TLabel;
    edAlto: TcxSpinEdit;
    lblKerf: TLabel;
    edKerf: TcxSpinEdit;
    lblPaso: TLabel;
    edPaso: TcxSpinEdit;
    lblGravedad: TLabel;
    cbGravedad: TcxComboBox;
    lblMargenes: TLabel;
    edMargIzq: TcxSpinEdit;
    edMargDer: TcxSpinEdit;
    edMargSup: TcxSpinEdit;
    edMargInf: TcxSpinEdit;
    // --- catalogo de formas ---
    lblForma: TLabel;
    cbForma: TcxComboBox;
    lblP1: TLabel;
    edP1: TcxSpinEdit;
    lblP2: TLabel;
    edP2: TcxSpinEdit;
    lblCant: TLabel;
    edCant: TcxSpinEdit;
    lblVeta: TLabel;
    cbVeta: TcxComboBox;
    lblOrden: TLabel;
    cbOrden: TcxComboBox;
    btnAddForma: TcxButton;
    btnPoligono: TcxButton;
    btnImportDxf: TcxButton;
    btnUp: TcxButton;
    btnDown: TcxButton;
    // --- grid de piezas ---
    gridPiezas: TcxGrid;
    tvPiezas: TcxGridTableView;
    colPzNombre: TcxGridColumn;
    colPzCantidad: TcxGridColumn;
    colPzArea: TcxGridColumn;
    colPzVeta: TcxGridColumn;
    lvPiezas: TcxGridLevel;
    btnDelPieza: TcxButton;
    // --- acciones ---
    btnCalcular: TcxButton;
    btnExportPNG: TcxButton;
    btnExportCSV: TcxButton;
    btnExportDxf: TcxButton;
    btnCerrar: TcxButton;
    btnMaximo: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure cbFormaPropertiesChange(Sender: TObject);
    procedure btnAddFormaClick(Sender: TObject);
    procedure btnPoligonoClick(Sender: TObject);
    procedure btnImportDxfClick(Sender: TObject);
    procedure btnDelPiezaClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnCalcularClick(Sender: TObject);
    procedure btnMaximoClick(Sender: TObject);
    procedure btnExportPNGClick(Sender: TObject);
    procedure btnExportCSVClick(Sender: TObject);
    procedure btnExportDxfClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure pbCanvasPaint(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure pbCanvasMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbCanvasMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure pbCanvasMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure tvPiezasEditValueChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
  private
    FPieces: TList<TNestPiece>;
    FNextId: Integer;
    FResult: TNestResult;
    FHasResult: Boolean;
    FColorSeq: Integer;        // secuencia para generar colores unicos por pieza
    FZoom: Double;             // factor de zoom del canvas (1 = ajuste automatico)
    FPanX, FPanY: Double;      // desplazamiento (pan) en pixeles
    FBaseScale: Double;        // escala base (mm->px) del ultimo dibujo, para el zoom
    FDragging: Boolean;        // pan con el raton en curso
    FDragX, FDragY: Integer;   // ultima posicion del raton durante el pan
    FCalculando: Boolean;      // hay un calculo en curso en un thread
    FCancel: Boolean;          // peticion de cancelacion para el motor
    FMostrarMaximo: Boolean;   // al terminar, mostrar mensaje de "maximo que cabe"
    FThread: TThread;          // thread de calculo en curso (nil si no hay)
    function CurrentVeta: TVetaMode;
    function ParamShape(AShapeIdx: Integer; P1, P2: Double): TPolygon2D;
    procedure AddPiece(const ABase: TPolygon2D; const ANombre: string;
      ACant: Integer; AVeta: TVetaMode);
    procedure RefreshGrid;
    procedure UpdateFormaLabels;
    procedure DibujaNesting(ACanvas: TCanvas; AW, AH: Integer);
    function LeerSheet: TSheet;
    procedure EjecutarNesting(const ASheet: TSheet;
      const APieces: TArray<TNestPiece>; ASoloUnaPlanxa, AParalelo: Boolean);
    procedure SyncGridToPieces;
    procedure FinNesting;
    function NextColor: Cardinal;
  public
    FMode: TNestingMode;
    procedure AplicarModo;
  end;

function ShowNesting2D(AOwner: TForm;
  AMode: TNestingMode = nmTrueShape): Boolean;

implementation

{$R *.dfm}

uses
  uNesting2DPoligonoEditor, uNesting2DDxf;

const
  SHAPE_RECT = 0;
  SHAPE_TRI  = 1;
  SHAPE_CIRC = 2;
  SHAPE_L    = 3;
  SHAPE_T    = 4;

function ShowNesting2D(AOwner: TForm; AMode: TNestingMode): Boolean;
var
  F: TfrmNesting2D;
begin
  F := TfrmNesting2D.Create(AOwner);
  try
    F.FMode := AMode;
    F.AplicarModo;
    F.ShowModal;
    Result := True;
  finally
    F.Free;
  end;
end;

{ ------------------------------------------------------------ ciclo de vida --- }

procedure TfrmNesting2D.FormCreate(Sender: TObject);
begin
  FPieces := TList<TNestPiece>.Create;
  FNextId := 1;
  FHasResult := False;
  FColorSeq := 0;   // cada pieza recibe un color unico (ver NextColor)
  FZoom := 1.0;
  FPanX := 0; FPanY := 0;
  FBaseScale := 0;
  // Anti-flicker: el panel del canvas con doble buffer y sin borrar el fondo
  // antes del OnPaint (ya dibujamos todo sobre un TBitmap y hacemos un solo Draw).
  pnlCanvas.DoubleBuffered := True;
  pnlCanvas.FullRepaint := False;

  cbForma.Properties.Items.Clear;
  cbForma.Properties.Items.Add('Rect'#225'ngulo (ancho x alto)');
  cbForma.Properties.Items.Add('Tri'#225'ngulo (base x altura)');
  cbForma.Properties.Items.Add('C'#237'rculo (di'#225'metro)');
  cbForma.Properties.Items.Add('Forma en L (lado x grosor)');
  cbForma.Properties.Items.Add('Forma en T (ancho x grosor)');
  cbForma.ItemIndex := SHAPE_RECT;

  cbVeta.Properties.Items.Clear;
  cbVeta.Properties.Items.Add('Libre (cualquier giro)');
  cbVeta.Properties.Items.Add('0 y 180'#176);
  cbVeta.Properties.Items.Add('Fija (sin girar)');
  cbVeta.ItemIndex := 0;

  cbGravedad.Properties.Items.Clear;
  cbGravedad.Properties.Items.Add('Abajo');
  cbGravedad.Properties.Items.Add('Arriba');
  cbGravedad.Properties.Items.Add('Izquierda');
  cbGravedad.Properties.Items.Add('Derecha');
  cbGravedad.ItemIndex := 0;

  cbOrden.Properties.Items.Clear;
  cbOrden.Properties.Items.Add('Optimizar (mezclar piezas)');
  cbOrden.Properties.Items.Add('Respetar orden del grid');
  cbOrden.ItemIndex := 0;

  UpdateFormaLabels;
  RefreshGrid;
end;

procedure TfrmNesting2D.AplicarModo;
begin
  // Rectangular: solo se ofrece el rectangulo y se oculta el poligono libre.
  // True-Shape: catalogo completo + poligono libre.
  if FMode = nmRectangular then
  begin
    Caption := 'Rectangular Nesting 2D - Encaje de piezas';
    lblTitle.Caption := 'Rectangular Nesting 2D';
    lblSubtitle.Caption :=
      'Distribuye piezas rectangulares maximizando el aprovechamiento';
    cbForma.Properties.Items.Clear;
    cbForma.Properties.Items.Add('Rect'#225'ngulo (ancho x alto)');
    cbForma.ItemIndex := 0;
    cbForma.Enabled := False;         // en rectangular no hay mas formas
    btnPoligono.Visible := False;     // sin poligono libre
    UpdateFormaLabels;
  end
  else
  begin
    Caption := 'True-Shape Nesting 2D - Encaje de piezas';
    lblTitle.Caption := 'True-Shape Nesting 2D';
    lblSubtitle.Caption :=
      'Encaja formas irregulares maximizando el aprovechamiento';
    btnPoligono.Visible := True;
    cbForma.Enabled := True;
  end;
end;

procedure TfrmNesting2D.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  T: Integer;
begin
  // Si hay un calculo en curso, pedir cancelacion y esperar (sin bloquear del
  // todo) a que el thread salga. El thread es FreeOnTerminate, asi que NO se
  // hace WaitFor sobre el (se autolibera); se espera por la bandera FCalculando,
  // que el propio thread pone a False al terminar via Synchronize. El motor
  // consulta FCancel a menudo y sale rapido.
  if FCalculando then
  begin
    FCancel := True;
    Screen.Cursor := crHourGlass;
    try
      T := 0;
      while FCalculando and (T < 5000) do   // como mucho 5 s de cortesia
      begin
        Application.ProcessMessages;         // deja correr el Synchronize
        Sleep(5);
        Inc(T, 5);
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
  CanClose := True;
end;

procedure TfrmNesting2D.FormDestroy(Sender: TObject);
begin
  FCancel := True;   // por si quedara algo vivo, que salga
  FPieces.Free;
end;

{ ------------------------------------------------------------ formas param --- }

function TfrmNesting2D.CurrentVeta: TVetaMode;
begin
  case cbVeta.ItemIndex of
    1: Result := vm0y180;
    2: Result := vmFija;
  else
    Result := vmLibre;
  end;
end;

procedure TfrmNesting2D.UpdateFormaLabels;
begin
  // Ajusta etiquetas y visibilidad del 2o parametro segun la forma.
  case cbForma.ItemIndex of
    SHAPE_RECT:
      begin lblP1.Caption := 'Ancho (mm)'; lblP2.Caption := 'Alto (mm)'; edP2.Visible := True; lblP2.Visible := True; end;
    SHAPE_TRI:
      begin lblP1.Caption := 'Base (mm)'; lblP2.Caption := 'Altura (mm)'; edP2.Visible := True; lblP2.Visible := True; end;
    SHAPE_CIRC:
      begin lblP1.Caption := 'Di'#225'metro (mm)'; edP2.Visible := False; lblP2.Visible := False; end;
    SHAPE_L:
      begin lblP1.Caption := 'Lado (mm)'; lblP2.Caption := 'Grosor (mm)'; edP2.Visible := True; lblP2.Visible := True; end;
    SHAPE_T:
      begin lblP1.Caption := 'Ancho (mm)'; lblP2.Caption := 'Grosor (mm)'; edP2.Visible := True; lblP2.Visible := True; end;
  end;
end;

procedure TfrmNesting2D.cbFormaPropertiesChange(Sender: TObject);
begin
  UpdateFormaLabels;
end;

function TfrmNesting2D.ParamShape(AShapeIdx: Integer; P1, P2: Double): TPolygon2D;
var
  I, N: Integer;
  R, Ang: Double;
  L: TList<TPt2D>;
begin
  case AShapeIdx of
    SHAPE_RECT:
      Result := TPolygon2D.FromCoords([0, 0, P1, 0, P1, P2, 0, P2]);
    SHAPE_TRI:
      Result := TPolygon2D.FromCoords([0, 0, P1, 0, P1 / 2, P2]);
    SHAPE_CIRC:
      begin
        R := P1 / 2;
        N := 32;   // circulo aproximado por poligono de 32 lados
        L := TList<TPt2D>.Create;
        try
          for I := 0 to N - 1 do
          begin
            Ang := 2 * Pi * I / N;
            L.Add(TPt2D.Make(R + R * Cos(Ang), R + R * Sin(Ang)));
          end;
          Result.Pts := L.ToArray;
        finally
          L.Free;
        end;
      end;
    SHAPE_L:
      // L: lado P1, grosor P2. Contorno en 6 vertices.
      Result := TPolygon2D.FromCoords(
        [0, 0, P1, 0, P1, P2, P2, P2, P2, P1, 0, P1]);
    SHAPE_T:
      // T: ancho total P1, grosor P2, altura = P1. Barra arriba + pie centrado.
      Result := TPolygon2D.FromCoords(
        [0, 0, P1, 0, P1, P2,
         (P1 + P2) / 2, P2, (P1 + P2) / 2, P1,
         (P1 - P2) / 2, P1, (P1 - P2) / 2, P2, 0, P2]);
  else
    Result := TPolygon2D.FromCoords([0, 0, P1, 0, P1, P2, 0, P2]);
  end;
end;

function TfrmNesting2D.NextColor: Cardinal;
var
  H, S, V, R, G, B: Double;
  I: Integer;
  P, Q, T, F: Double;
begin
  // Color UNICO por pieza: se reparte el matiz (hue) con el "golden ratio" para
  // que colores consecutivos sean bien distintos y NUNCA se repitan, por muchas
  // piezas que haya. Saturacion/brillo fijos para que todos se vean bien.
  H := Frac(FColorSeq * 0.6180339887);   // 0.618 = 1/golden ratio
  Inc(FColorSeq);
  S := 0.62;
  V := 0.80;

  // HSV -> RGB.
  I := Trunc(H * 6);
  F := H * 6 - I;
  P := V * (1 - S);
  Q := V * (1 - F * S);
  T := V * (1 - (1 - F) * S);
  case I mod 6 of
    0: begin R := V; G := T; B := P; end;
    1: begin R := Q; G := V; B := P; end;
    2: begin R := P; G := V; B := T; end;
    3: begin R := P; G := Q; B := V; end;
    4: begin R := T; G := P; B := V; end;
  else begin R := V; G := P; B := Q; end;
  end;

  // ARGB (alfa opaco). El dibujo usa MakeColor(A,R,G,B) via P.Color.
  Result := $FF000000 or
            (Cardinal(Round(R * 255)) shl 16) or
            (Cardinal(Round(G * 255)) shl 8) or
             Cardinal(Round(B * 255));
end;

procedure TfrmNesting2D.AddPiece(const ABase: TPolygon2D; const ANombre: string;
  ACant: Integer; AVeta: TVetaMode);
var
  P: TNestPiece;
begin
  P.Id := FNextId; Inc(FNextId);
  P.Nombre := ANombre;
  P.Base := ABase;
  P.Cantidad := Max(1, ACant);
  P.Veta := AVeta;
  P.Color := NextColor;
  FPieces.Add(P);
  RefreshGrid;
end;

procedure TfrmNesting2D.btnAddFormaClick(Sender: TObject);
var
  P1, P2: Double;
  Base: TPolygon2D;
  Nom: string;
begin
  P1 := edP1.Value;
  P2 := edP2.Value;
  if P1 <= 0 then
  begin
    ShowMessage('Introduce una medida valida.');
    Exit;
  end;
  if (cbForma.ItemIndex <> SHAPE_CIRC) and (P2 <= 0) then
  begin
    ShowMessage('Introduce la segunda medida.');
    Exit;
  end;
  Base := ParamShape(cbForma.ItemIndex, P1, P2);
  Nom := VarToStr(cbForma.Properties.Items[cbForma.ItemIndex]);
  Nom := Copy(Nom, 1, Pos(' ', Nom + ' ') - 1);   // primera palabra
  AddPiece(Base, Nom, Round(edCant.Value), CurrentVeta);
end;

procedure TfrmNesting2D.btnPoligonoClick(Sender: TObject);
var
  Poly: TPolygon2D;
begin
  if EditarPoligono2D(Self, Poly) then
    AddPiece(Poly, 'Pol'#237'gono', Round(edCant.Value), CurrentVeta);
end;

procedure TfrmNesting2D.btnImportDxfClick(Sender: TObject);
var
  Dlg: TOpenDialog;
  Contours: TArray<TDxfContour>;
  I, N: Integer;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'Dibujo DXF (*.dxf)|*.dxf|Todos (*.*)|*.*';
    Dlg.DefaultExt := 'dxf';
    if not Dlg.Execute then Exit;

    try
      Contours := ImportDxfContours(Dlg.FileName, 32);
    except
      on E: Exception do
      begin
        ShowMessage('No se pudo leer el DXF: ' + E.Message);
        Exit;
      end;
    end;

    N := 0;
    for I := 0 to High(Contours) do
    begin
      // Cada contorno cerrado del DXF = una pieza (cantidad 1, veta actual).
      AddPiece(Contours[I].Poly, Contours[I].Nombre, 1, CurrentVeta);
      Inc(N);
    end;

    if N = 0 then
      ShowMessage('No se han encontrado contornos cerrados en el DXF.' + sLineBreak +
        'Se admiten LWPOLYLINE, POLYLINE y CIRCLE cerrados.')
    else
      ShowMessage(Format('Importadas %d piezas del DXF.', [N]));
  finally
    Dlg.Free;
  end;
end;

procedure TfrmNesting2D.btnDelPiezaClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := tvPiezas.Controller.FocusedRecordIndex;
  if (Idx >= 0) and (Idx < FPieces.Count) then
  begin
    FPieces.Delete(Idx);
    RefreshGrid;
  end;
end;

procedure TfrmNesting2D.btnUpClick(Sender: TObject);
var
  Idx: Integer;
begin
  SyncGridToPieces;
  Idx := tvPiezas.Controller.FocusedRecordIndex;
  if (Idx > 0) and (Idx < FPieces.Count) then
  begin
    FPieces.Exchange(Idx, Idx - 1);
    RefreshGrid;
    tvPiezas.Controller.FocusedRecordIndex := Idx - 1;
  end;
end;

procedure TfrmNesting2D.btnDownClick(Sender: TObject);
var
  Idx: Integer;
begin
  SyncGridToPieces;
  Idx := tvPiezas.Controller.FocusedRecordIndex;
  if (Idx >= 0) and (Idx < FPieces.Count - 1) then
  begin
    FPieces.Exchange(Idx, Idx + 1);
    RefreshGrid;
    tvPiezas.Controller.FocusedRecordIndex := Idx + 1;
  end;
end;

procedure TfrmNesting2D.RefreshGrid;
var
  I: Integer;
  P: TNestPiece;
  VetaTxt: string;
begin
  tvPiezas.BeginUpdate;
  try
    tvPiezas.DataController.RecordCount := FPieces.Count;
    for I := 0 to FPieces.Count - 1 do
    begin
      P := FPieces[I];
      case P.Veta of
        vm0y180: VetaTxt := '0/180';
        vmFija:  VetaTxt := 'Fija';
      else       VetaTxt := 'Libre';
      end;
      tvPiezas.DataController.Values[I, colPzNombre.Index] := P.Nombre;
      tvPiezas.DataController.Values[I, colPzCantidad.Index] := P.Cantidad;
      tvPiezas.DataController.Values[I, colPzArea.Index] :=
        Format('%.0f mm'#178, [P.Base.Area]);
      tvPiezas.DataController.Values[I, colPzVeta.Index] := VetaTxt;
    end;
  finally
    tvPiezas.EndUpdate;
  end;
end;

function VetaFromText(const S: string): TVetaMode;
begin
  if Pos('180', S) > 0 then Result := vm0y180
  else if SameText(Trim(S), 'Fija') then Result := vmFija
  else Result := vmLibre;
end;

function VarToStrSafe(const V: Variant): string;
begin
  // Conversion tolerante: evita "Invalid variant type" con valores varError o
  // tipos inesperados que devuelve el editor combo del grid.
  try
    if VarIsNull(V) or VarIsEmpty(V) then Exit('');
    Result := VarToStr(V);
  except
    Result := '';
  end;
end;

procedure TfrmNesting2D.tvPiezasEditValueChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
var
  Idx, Cant: Integer;
  P: TNestPiece;
  S: string;
  V: Variant;
begin
  // OnEditValueChanged (Sender, AItem) - misma firma que uBacklog/uGestionCentres.
  // NOTA: el "Invalid variant type" NO venia de aqui; venia de forzar
  // DataBinding.ValueTypeClass en FormCreate (ya eliminado). El grid unbound debe
  // dejar el tipo de valor LIBRE, como los grids que funcionan del proyecto.
  if AItem = nil then Exit;
  Idx := Sender.Controller.FocusedRecordIndex;
  if (Idx < 0) or (Idx >= FPieces.Count) then Exit;
  P := FPieces[Idx];

  // Valor "en vivo" del editor activo (patron del proyecto, ver uBacklog); si no
  // hay edicion activa, caer a AItem.EditValue.
  V := Null;
  if (Sender.Controller <> nil) and
     (Sender.Controller.EditingController <> nil) and
     (Sender.Controller.EditingController.Edit <> nil) then
    V := Sender.Controller.EditingController.Edit.EditingValue;
  if VarIsNull(V) or VarIsEmpty(V) then
    V := AItem.EditValue;

  if AItem = colPzCantidad then
  begin
    Cant := StrToIntDef(VarToStrSafe(V), P.Cantidad);
    if Cant < 1 then Cant := 1;
    P.Cantidad := Cant;
  end
  else if AItem = colPzVeta then
  begin
    S := VarToStrSafe(V);
    if S = '' then Exit;
    P.Veta := VetaFromText(S);
  end
  else
    Exit;

  FPieces[Idx] := P;
end;

{ ------------------------------------------------------------ calcular --- }

procedure TfrmNesting2D.SyncGridToPieces;
var
  I: Integer;
  P: TNestPiece;
  S: string;
  VCant, VVeta: Variant;
begin
  // Relee cantidad y veta del grid a FPieces justo antes de calcular. Asi el
  // valor editado se aplica siempre, aunque OnEditValueChanged no se disparara
  // (p.ej. si la celda queda con el editor abierto al pulsar el boton).
  try
    tvPiezas.DataController.PostEditingData;   // confirma la celda en edicion
  except
    // si no habia edicion activa, ignorar
  end;
  for I := 0 to FPieces.Count - 1 do
  begin
    if I >= tvPiezas.DataController.RecordCount then Break;
    P := FPieces[I];
    VCant := tvPiezas.DataController.Values[I, colPzCantidad.Index];
    S := VarToStrSafe(VCant);
    if S <> '' then P.Cantidad := Max(1, StrToIntDef(S, P.Cantidad));
    VVeta := tvPiezas.DataController.Values[I, colPzVeta.Index];
    S := VarToStrSafe(VVeta);
    if S <> '' then P.Veta := VetaFromText(S);
    FPieces[I] := P;
  end;
end;

function TfrmNesting2D.LeerSheet: TSheet;
begin
  Result.Ancho := edAncho.Value;
  Result.Alto := edAlto.Value;
  Result.MargenIzq := edMargIzq.Value;
  Result.MargenDer := edMargDer.Value;
  Result.MargenSup := edMargSup.Value;
  Result.MargenInf := edMargInf.Value;
end;

procedure TfrmNesting2D.btnCalcularClick(Sender: TObject);
var
  Sheet: TSheet;
begin
  if FPieces.Count = 0 then
  begin
    ShowMessage('Anade al menos una pieza.');
    Exit;
  end;
  Sheet := LeerSheet;
  if (Sheet.Ancho <= 0) or (Sheet.Alto <= 0) then
  begin
    ShowMessage('Define el tamano de la planxa.');
    Exit;
  end;
  if (Sheet.UtilAncho <= 0) or (Sheet.UtilAlto <= 0) then
  begin
    ShowMessage('Los m'#225'rgenes dejan area util nula. Reduce los m'#225'rgenes.');
    Exit;
  end;

  SyncGridToPieces;
  EjecutarNesting(Sheet, FPieces.ToArray, False, True);
end;

procedure TfrmNesting2D.btnMaximoClick(Sender: TObject);
var
  Sheet: TSheet;
  Pieces: TArray<TNestPiece>;
  P: TNestPiece;
  Cota: Integer;
  AreaPieza: Double;
begin
  if FPieces.Count <> 1 then
  begin
    ShowMessage('El c'#225'lculo autom'#225'tico del m'#225'ximo requiere UNA sola pieza en la lista.');
    Exit;
  end;
  SyncGridToPieces;   // recoge cantidad/veta editadas en el grid
  Sheet := LeerSheet;
  if (Sheet.Ancho <= 0) or (Sheet.Alto <= 0) then
  begin
    ShowMessage('Define el tamano de la planxa.');
    Exit;
  end;
  if (Sheet.UtilAncho <= 0) or (Sheet.UtilAlto <= 0) then
  begin
    ShowMessage('Los m'#225'rgenes dejan area util nula. Reduce los m'#225'rgenes.');
    Exit;
  end;

  // Cota superior teorica: area de la planxa / area de la pieza (nunca caben
  // mas). Se pide esa cantidad (limitada) y una sola planxa; el motor coloca
  // hasta que no cabe y corta (Break interno). Asi NO se piden miles de piezas
  // imposibles (eso saturaba la CPU). Se usa Run SIMPLE (no paralelo): con una
  // sola pieza repetida las 8 estrategias darian lo mismo y multiplicarian x8
  // el trabajo.
  AreaPieza := FPieces[0].Base.Area;
  if AreaPieza <= 0 then AreaPieza := 1;
  // Cota sobre el area UTIL (planxa menos margenes).
  Cota := Ceil((Sheet.UtilAncho * Sheet.UtilAlto) / AreaPieza) + 2;
  if Cota < 1 then Cota := 1;
  if Cota > 2000 then Cota := 2000;           // tope absoluto de seguridad

  P := FPieces[0];
  P.Cantidad := Cota;
  SetLength(Pieces, 1);
  Pieces[0] := P;

  FMostrarMaximo := True;   // FinNesting mostrara el mensaje al terminar el thread
  EjecutarNesting(Sheet, Pieces, True, False);   // False = sin paralelo
end;

procedure TfrmNesting2D.EjecutarNesting(const ASheet: TSheet;
  const APieces: TArray<TNestPiece>; ASoloUnaPlanxa, AParalelo: Boolean);
var
  Params: TNestParams;
  LSheet: TSheet;
  LPieces: TArray<TNestPiece>;
begin
  if FCalculando then Exit;   // evita reentrada (doble clic)

  Params := TNestParams.Default;
  Params.Kerf := edKerf.Value;
  Params.GridStep := edPaso.Value;
  if Params.GridStep <= 0 then Params.GridStep := 5;
  if ASoloUnaPlanxa then Params.MaxSheets := 1;
  case cbGravedad.ItemIndex of
    1: Params.Gravity := gdUp;
    2: Params.Gravity := gdLeft;
    3: Params.Gravity := gdRight;
  else Params.Gravity := gdDown;
  end;

  // Orden de piezas: "Respetar orden del grid" (1) fuerza estrategia de orden de
  // entrada y desactiva el multi-start (que reordenaria). "Optimizar/mezclar" (0)
  // deja el paralelo probar varias estrategias.
  if cbOrden.ItemIndex = 1 then
  begin
    Params.Strategy := nsGridOrder;
    AParalelo := False;
  end;

  // Copias locales para pasarlas al thread (no tocar campos de UI desde el hilo).
  LSheet := ASheet;
  LPieces := Copy(APieces, 0, Length(APieces));

  FCalculando := True;
  FCancel := False;
  Screen.Cursor := crHourGlass;
  lblMetrics.Caption := 'Calculando...';
  btnCalcular.Enabled := False;
  btnMaximo.Enabled := False;

  // El nesting es matematica pura (sin ADO/COM): se ejecuta en un thread para no
  // bloquear la UI. FreeOnTerminate=True: el thread se autolibera al acabar, asi
  // no hay fugas ni referencias que se queden "vivas" y bloqueen el 2o calculo
  // (ese era el bug de "solo el primer clic actualiza"). La cancelacion al
  // cerrar se hace por bandera FCancel; el resultado se vuelca con Synchronize
  // (no Queue) para que se aplique de forma sincrona antes de reactivar botones.
  FThread := TThread.CreateAnonymousThread(
    procedure
    var
      Engine: INesting2DEngine;
      LResult: TNestResult;
    begin
      try
        Engine := CreateNesting2DEngine;
        if AParalelo then
          LResult := Engine.RunParallel(LSheet, LPieces, Params,
            function(AFraction: Double): Boolean
            begin
              Result := not FCancel;
            end)
        else
          LResult := Engine.Run(LSheet, LPieces, Params,
            function(AFraction: Double): Boolean
            begin
              Result := not FCancel;
            end);
      except
        // Ante cualquier error, garantizar que la UI se desbloquea.
        LResult := Default(TNestResult);
      end;

      TThread.Synchronize(nil,
        procedure
        begin
          FThread := nil;          // el thread ya termina (se autolibera)
          FCalculando := False;
          Screen.Cursor := crDefault;
          btnCalcular.Enabled := True;
          btnMaximo.Enabled := True;
          if not FCancel then
          begin
            FResult := LResult;
            FHasResult := True;
            FinNesting;            // actualiza metricas + repinta la planxa
          end;
        end);
    end);
  FThread.FreeOnTerminate := True;
  FThread.Start;
end;

procedure TfrmNesting2D.FinNesting;
var
  M: TNestMetrics;
begin
  M := FResult.Metrics;

  if FMostrarMaximo then
  begin
    // Modo "Maximo que cabe": el total solicitado (TotalPiezas) es una cota
    // interna alta, no algo que el usuario pidiera; mostrar solo las que caben.
    lblMetrics.Caption := Format(
      'Planxas: %d    Caben: %d piezas' + sLineBreak +
      'Aprovechamiento: %.1f%%    Retal: %.0f mm'#178 + sLineBreak +
      'Libre: %.0f mm ancho (%.0f%%)  |  %.0f mm alto (%.0f%%)',
      [M.NumSheets, M.PiezasColocadas, M.Aprovechamiento * 100, M.AreaRetal,
       M.LibreAncho, M.LibreAnchoPct * 100, M.LibreAlto, M.LibreAltoPct * 100]);
  end
  else
  begin
    // Modo normal: piezas colocadas / solicitadas.
    lblMetrics.Caption := Format(
      'Planxas: %d    Piezas: %d/%d    Sin colocar: %d' + sLineBreak +
      'Aprovechamiento: %.1f%%    Retal: %.0f mm'#178 + sLineBreak +
      'Libre: %.0f mm ancho (%.0f%%)  |  %.0f mm alto (%.0f%%)',
      [M.NumSheets, M.PiezasColocadas, M.TotalPiezas, M.PiezasSinColocar,
       M.Aprovechamiento * 100, M.AreaRetal,
       M.LibreAncho, M.LibreAnchoPct * 100, M.LibreAlto, M.LibreAltoPct * 100]);
  end;

  pbCanvas.Invalidate;

  if FMostrarMaximo then
  begin
    FMostrarMaximo := False;
    ShowMessage(Format('Caben %d piezas en una planxa (aprovechamiento %.1f%%).',
      [M.PiezasColocadas, M.Aprovechamiento * 100]));
  end;
end;

{ ------------------------------------------------------------ dibujo --- }

procedure TfrmNesting2D.pbCanvasPaint(Sender: TObject);
begin
  DibujaNesting(pbCanvas.Canvas, pbCanvas.Width, pbCanvas.Height);
end;

procedure TfrmNesting2D.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  Pt: TPoint;
  OldZoom, Factor, WorldX, WorldY: Double;
begin
  // El form recibe la rueda (OnMouseWheel del control es protegido). Solo actua
  // si el cursor esta sobre el PaintBox del canvas.
  Pt := pbCanvas.ScreenToClient(MousePos);
  if (Pt.X < 0) or (Pt.Y < 0) or
     (Pt.X > pbCanvas.Width) or (Pt.Y > pbCanvas.Height) then Exit;

  OldZoom := FZoom;
  if WheelDelta > 0 then Factor := 1.15 else Factor := 1 / 1.15;
  FZoom := FZoom * Factor;
  if FZoom < 0.1 then FZoom := 0.1;
  if FZoom > 40 then FZoom := 40;

  // Ajustar el pan para que (Pt) siga apuntando al mismo punto del dibujo.
  // pantalla = base*zoom*mundo + pan  =>  mantener 'mundo' bajo el cursor.
  if FBaseScale > 0 then
  begin
    WorldX := (Pt.X - FPanX) / (FBaseScale * OldZoom);
    WorldY := (Pt.Y - FPanY) / (FBaseScale * OldZoom);
    FPanX := Pt.X - WorldX * FBaseScale * FZoom;
    FPanY := Pt.Y - WorldY * FBaseScale * FZoom;
  end;

  pbCanvas.Invalidate;
  Handled := True;
end;

procedure TfrmNesting2D.pbCanvasMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // Arrastrar con boton izquierdo o central = pan.
  if Button in [mbLeft, mbMiddle] then
  begin
    FDragging := True;
    FDragX := X; FDragY := Y;
    pbCanvas.Cursor := crSizeAll;
  end;
end;

procedure TfrmNesting2D.pbCanvasMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if FDragging then
  begin
    FPanX := FPanX + (X - FDragX);
    FPanY := FPanY + (Y - FDragY);
    FDragX := X; FDragY := Y;
    pbCanvas.Invalidate;
  end;
end;

procedure TfrmNesting2D.pbCanvasMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
  pbCanvas.Cursor := crDefault;
end;

procedure TfrmNesting2D.DibujaNesting(ACanvas: TCanvas; AW, AH: Integer);
const
  RULER = 22;    // ancho de las reglas (arriba y a la izquierda), en px
  EPS_UI = 1e-6;
var
  Buf: TBitmap;
  G: TGPGraphics;
  I, J, N, SheetsAcross, Col, Row, SheetIdx: Integer;
  Scale, SheetW, SheetH, Gap, OffX, OffY, FitScale: Double;
  P: TPlacement;
  Pen: TGPPen;
  Brush: TGPSolidBrush;
  SheetPen: TGPPen;
  SheetBrush: TGPSolidBrush;
  MargPen: TGPPen;
  pts: array of TGPPointF;

  // Reglas: marcas cada "step" mm, con etiqueta. Se dibujan en las franjas
  // superior (X) e izquierda (Y), en coordenadas de pantalla ya con zoom/pan.
  procedure DrawRulers;
  var
    stepMM: Double;
    mm, px: Double;
    S: string;
  begin
    // Fondo de las franjas.
    Buf.Canvas.Brush.Color := TColor($00E8E8E8);
    Buf.Canvas.FillRect(Rect(0, 0, AW, RULER));
    Buf.Canvas.FillRect(Rect(0, 0, RULER, AH));
    Buf.Canvas.Font.Color := clGray;
    Buf.Canvas.Font.Height := -9;

    // Paso de marca adaptativo segun escala (que no se amontonen).
    stepMM := 10;
    while stepMM * Scale < 45 do stepMM := stepMM * 5;   // 10,50,250,1250...
    while stepMM * Scale > 220 do stepMM := stepMM / 2;

    // Regla horizontal (X). El origen mundo X=0 esta en pantalla en FPanX+RULER.
    mm := 0;
    while True do
    begin
      px := RULER + FPanX + mm * Scale;
      if px > AW then Break;
      if px >= RULER then
      begin
        Buf.Canvas.Pen.Color := TColor($00B0B0B0);
        Buf.Canvas.MoveTo(Round(px), RULER - 6);
        Buf.Canvas.LineTo(Round(px), RULER);
        S := IntToStr(Round(mm));
        Buf.Canvas.TextOut(Round(px) + 2, 2, S);
      end;
      mm := mm + stepMM;
    end;

    // Regla vertical (Y). Y crece hacia arriba en el mundo; en pantalla el 0
    // esta abajo de cada planxa, pero para la regla usamos coordenada pantalla.
    mm := 0;
    while True do
    begin
      px := RULER + FPanY + mm * Scale;
      if px > AH then Break;
      if px >= RULER then
      begin
        Buf.Canvas.Pen.Color := TColor($00B0B0B0);
        Buf.Canvas.MoveTo(RULER - 6, Round(px));
        Buf.Canvas.LineTo(RULER, Round(px));
        S := IntToStr(Round(mm));
        Buf.Canvas.TextOut(2, Round(px) + 1, S);
      end;
      mm := mm + stepMM;
    end;
    // Esquina.
    Buf.Canvas.Brush.Color := TColor($00D8D8D8);
    Buf.Canvas.FillRect(Rect(0, 0, RULER, RULER));
  end;

  // Rejilla de puntos sobre una planxa (en OffX,OffY con la escala dada).
  procedure DrawDotGrid(AG: TGPGraphics; AOffX, AOffY, ASheetW, ASheetH,
    AScale: Double);
  var
    DotBrush: TGPSolidBrush;
    gridMM, gx, gy, px, py: Double;
    r: Single;
  begin
    // Paso adaptativo: empezar en 50mm y ajustar para que no se amontonen.
    gridMM := 50;
    while gridMM * AScale < 14 do gridMM := gridMM * 2;
    while gridMM * AScale > 90 do gridMM := gridMM / 2;
    if gridMM < 1 then gridMM := 1;

    r := 1.1;
    DotBrush := TGPSolidBrush.Create(MakeColor(255, 175, 175, 175));
    try
      gy := 0;
      while gy <= ASheetH + EPS_UI do
      begin
        py := AOffY + (ASheetH - gy) * AScale;   // Y mundo->pantalla
        gx := 0;
        while gx <= ASheetW + EPS_UI do
        begin
          px := AOffX + gx * AScale;
          AG.FillEllipse(DotBrush, Single(px - r), Single(py - r), 2 * r, 2 * r);
          gx := gx + gridMM;
        end;
        gy := gy + gridMM;
      end;
    finally
      DotBrush.Free;
    end;
  end;

begin
  Buf := TBitmap.Create;
  try
    Buf.PixelFormat := pf24bit;
    Buf.SetSize(AW, AH);
    Buf.Canvas.Brush.Color := clWhite;
    Buf.Canvas.FillRect(Rect(0, 0, AW, AH));

    if not FHasResult or (FResult.Metrics.NumSheets = 0) then
    begin
      Buf.Canvas.Font.Color := clGray;
      Buf.Canvas.TextOut(16, 16,
        'Define piezas y planxa, y pulsa "Calcular encaje".');
      ACanvas.Draw(0, 0, Buf);
      Exit;
    end;

    SheetW := FResult.Sheet.Ancho;
    SheetH := FResult.Sheet.Alto;
    Gap := 16;

    // Escala base (ajuste automatico) para que una fila de planxas quepa en el
    // area disponible (descontando las reglas). Luego se multiplica por FZoom.
    N := FResult.Metrics.NumSheets;
    SheetsAcross := Max(1, Trunc((AW - RULER) / (SheetW * 0.05 + Gap)));
    if SheetsAcross > N then SheetsAcross := N;
    FitScale := (AW - RULER - Gap * (SheetsAcross + 1)) / (SheetsAcross * SheetW);
    if FitScale * SheetH > AH - RULER - 30 then
      FitScale := (AH - RULER - 30) / SheetH;
    if FitScale <= 0 then FitScale := 0.05;
    FBaseScale := FitScale;
    Scale := FitScale * FZoom;

    G := TGPGraphics.Create(Buf.Canvas.Handle);
    try
      G.SetSmoothingMode(SmoothingModeAntiAlias);

      SheetBrush := TGPSolidBrush.Create(MakeColor(255, 245, 245, 245));
      SheetPen := TGPPen.Create(MakeColor(255, 120, 120, 120), 1.2);
      try
        for SheetIdx := 0 to N - 1 do
        begin
          Col := SheetIdx mod SheetsAcross;
          Row := SheetIdx div SheetsAcross;
          // Offset: reglas + pan + posicion de la planxa en la cuadricula.
          OffX := RULER + FPanX + Gap + Col * (SheetW * Scale + Gap);
          OffY := RULER + FPanY + Gap + Row * (SheetH * Scale + Gap + 14);

          // Fondo de la planxa.
          G.FillRectangle(SheetBrush, OffX, OffY, SheetW * Scale, SheetH * Scale);

          // Rejilla de puntos (cada GridMM mm) sobre la planxa. Ayuda a leer
          // posiciones. El paso se adapta a la escala para no saturar.
          DrawDotGrid(G, OffX, OffY, SheetW, SheetH, Scale);

          G.DrawRectangle(SheetPen, OffX, OffY, SheetW * Scale, SheetH * Scale);

          // Area util (planxa menos margenes): rectangulo discontinuo rojo, solo
          // si hay algun margen definido.
          with FResult.Sheet do
            if (MargenIzq > 0) or (MargenDer > 0) or (MargenSup > 0) or (MargenInf > 0) then
            begin
              MargPen := TGPPen.Create(MakeColor(200, 210, 70, 70), 1.0);
              try
                MargPen.SetDashStyle(DashStyleDash);
                // El area util en pantalla: X=[MargIzq..Ancho-MargDer],
                // Y mundo=[MargInf..Alto-MargSup] -> pantalla invertida.
                G.DrawRectangle(MargPen,
                  OffX + MargenIzq * Scale,
                  OffY + MargenSup * Scale,
                  UtilAncho * Scale,
                  UtilAlto * Scale);
              finally
                MargPen.Free;
              end;
            end;

          Buf.Canvas.Font.Color := clGray;
          Buf.Canvas.Font.Height := -11;
          Buf.Canvas.TextOut(Round(OffX), Round(OffY + SheetH * Scale + 1),
            Format('Planxa %d', [SheetIdx + 1]));

          // Piezas de esta planxa.
          for I := 0 to High(FResult.Placements) do
          begin
            P := FResult.Placements[I];
            if P.SheetIndex <> SheetIdx then Continue;
            SetLength(pts, P.Placed.Count);
            for J := 0 to P.Placed.Count - 1 do
              pts[J] := MakePoint(
                Single(OffX + P.Placed.Pts[J].X * Scale),
                // Y del mundo (abajo->arriba) a Y de pantalla (arriba->abajo):
                Single(OffY + (SheetH - P.Placed.Pts[J].Y) * Scale));
            Brush := TGPSolidBrush.Create(P.Color and $FFFFFFFF);
            Pen := TGPPen.Create(MakeColor(255, 40, 40, 40), 1.0);
            try
              G.FillPolygon(Brush, PGPPointF(@pts[0]), P.Placed.Count);
              G.DrawPolygon(Pen, PGPPointF(@pts[0]), P.Placed.Count);
            finally
              Brush.Free;
              Pen.Free;
            end;
          end;
        end;
      finally
        SheetBrush.Free;
        SheetPen.Free;
      end;
    finally
      G.Free;
    end;

    DrawRulers;   // reglas encima (franjas), con las marcas segun zoom/pan

    ACanvas.Draw(0, 0, Buf);
  finally
    Buf.Free;
  end;
end;

{ ------------------------------------------------------------ export --- }

procedure TfrmNesting2D.btnExportPNGClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Bmp: TBitmap;
  Png: TPngImage;
begin
  if not FHasResult then
  begin
    ShowMessage('Primero calcula el encaje.');
    Exit;
  end;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Imagen PNG (*.png)|*.png';
    Dlg.DefaultExt := 'png';
    Dlg.FileName := 'Nesting.png';
    if not Dlg.Execute then Exit;
    Bmp := TBitmap.Create;
    try
      Bmp.PixelFormat := pf24bit;
      Bmp.SetSize(pbCanvas.Width, pbCanvas.Height);
      DibujaNesting(Bmp.Canvas, Bmp.Width, Bmp.Height);
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
    ShowMessage('Imagen exportada.');
  finally
    Dlg.Free;
  end;
end;

procedure TfrmNesting2D.btnExportCSVClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  SL: TStringList;
  I: Integer;
  P: TPlacement;
  Fmt: TFormatSettings;
begin
  if not FHasResult then
  begin
    ShowMessage('Primero calcula el encaje.');
    Exit;
  end;
  Fmt := TFormatSettings.Invariant;
  Dlg := TSaveDialog.Create(nil);
  SL := TStringList.Create;
  try
    Dlg.Filter := 'CSV (*.csv)|*.csv';
    Dlg.DefaultExt := 'csv';
    Dlg.FileName := 'Nesting.csv';
    if not Dlg.Execute then Exit;
    SL.Add('Planxa;Pieza;Angulo;OffsetX;OffsetY;AreaMM2');
    for I := 0 to High(FResult.Placements) do
    begin
      P := FResult.Placements[I];
      SL.Add(Format('%d;%s;%.1f;%.2f;%.2f;%.1f',
        [P.SheetIndex + 1, P.Nombre, P.AngleDeg, P.OffsetX, P.OffsetY,
         P.Placed.Area], Fmt));
    end;
    SL.SaveToFile(Dlg.FileName, TEncoding.UTF8);
    ShowMessage('Listado exportado.');
  finally
    SL.Free;
    Dlg.Free;
  end;
end;

procedure TfrmNesting2D.btnExportDxfClick(Sender: TObject);
var
  Dlg: TSaveDialog;
begin
  if not FHasResult then
  begin
    ShowMessage('Primero calcula el encaje.');
    Exit;
  end;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Dibujo DXF (*.dxf)|*.dxf';
    Dlg.DefaultExt := 'dxf';
    Dlg.FileName := 'Nesting.dxf';
    if not Dlg.Execute then Exit;
    try
      ExportDxfResult(Dlg.FileName, FResult);
      ShowMessage('Planxa exportada a DXF (capas PLANXA y PIEZAS).');
    except
      on E: Exception do
        ShowMessage('No se pudo exportar el DXF: ' + E.Message);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmNesting2D.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
