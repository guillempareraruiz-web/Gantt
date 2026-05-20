unit uMatrizPolivalencia;

{
  Matriz de polivalencia (skills matrix): filas = operarios, columnas =
  habilidades, celdas = nivel del operario en esa habilidad con color de
  fondo seg'un nivel (estilo skills-matrix de management visual).

  Mapeo de niveles -> color y etiqueta corta:
    No formado     - gris muy claro,  '---'  (operario no tiene la habilidad)
    Aprendiz       - verde claro,     'Apr.'
    Junior         - verde medio,     'Jr.'
    Senior         - verde oscuro,    'Sr.'
    Experto        - verde muy osc.,  'Exp.'

  Los nombres "Aprendiz/Junior/Senior/Experto" vienen de TNivelSkill en
  uOperariosTypes. Las abreviaturas son lo que muestran las celdas.

  El form es solo lectura. Para editar polivalencia se usa el dialogo
  existente uOperarioPolivalencia desde uGestionOperaris.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ExtDlgs,
  uOperariosTypes, uOperariosRepo, uHabilidadRepo, uPlanProdTypes;

type
  TfrmMatrizPolivalencia = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlLegend: TPanel;
    pbLegend: TPaintBox;
    pnlBottom: TPanel;
    lblFooter: TLabel;
    btnClose: TButton;
    sbMatrix: TScrollBox;
    pbMatrix: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure pbLegendPaint(Sender: TObject);
    procedure pbMatrixPaint(Sender: TObject);
  private
    FOperariosRepo: TOperariosRepo;
    FHabRepo: THabilidadRepo;
    FOperarios: TArray<TOperario>;
    FHabilidades: TArray<THabilidad>;
    // cache: nivel por (OperarioId, CodHabilidad). -1 = no formado.
    FNivel: TDictionary<string, Integer>;
    procedure LoadData;
    function KeyFor(OperarioId: Integer; const CodHab: string): string;
    function GetNivel(OperarioId: Integer; const CodHab: string;
      out Found: Boolean): TNivelSkill;
    procedure ComputeMatrixSize(out AWidth, AHeight: Integer);
  public
    class procedure Execute(AOperariosRepo: TOperariosRepo;
      AHabRepo: THabilidadRepo);
  end;

implementation

{$R *.dfm}

const
  // Dimensiones (untyped: valors enters per a aritmetica)
  CELL_W       = 90;
  CELL_H       = 38;
  ROW_LABEL_W  = 140;
  COL_HEADER_H = 46;
  MTX_PADDING      = 12;

const
  // Colores: typed const TColor per evitar inferencia ambigua amb les Integer
  CLR_NO_SKILL:   TColor = $00E8E8E8;
  CLR_APRENDIZ:   TColor = $0099DDB8;
  CLR_JUNIOR:     TColor = $0069C684;
  CLR_SENIOR:     TColor = $004FA868;
  CLR_EXPERTO:    TColor = $00357A4A;
  CLR_TEXT_LIGHT: TColor = $00404040;
  CLR_TEXT_DARK:  TColor = $00FFFFFF;
  CLR_GRID_LINE:  TColor = $00D0D0D0;
  CLR_HEADER_BG:  TColor = $00F5F1E8;
  CLR_HEADER_TX:  TColor = $00404040;
  CLR_PAPER:      TColor = $00FCFAF4;

class procedure TfrmMatrizPolivalencia.Execute(AOperariosRepo: TOperariosRepo;
  AHabRepo: THabilidadRepo);
var
  F: TfrmMatrizPolivalencia;
begin
  F := TfrmMatrizPolivalencia.Create(nil);
  try
    F.FOperariosRepo := AOperariosRepo;
    F.FHabRepo := AHabRepo;
    F.LoadData;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmMatrizPolivalencia.FormCreate(Sender: TObject);
begin
  FNivel := TDictionary<string, Integer>.Create;
  DoubleBuffered := True;
  sbMatrix.DoubleBuffered := True;
end;

procedure TfrmMatrizPolivalencia.FormDestroy(Sender: TObject);
begin
  FNivel.Free;
end;

procedure TfrmMatrizPolivalencia.btnCloseClick(Sender: TObject);
begin
  Close;
end;

function TfrmMatrizPolivalencia.KeyFor(OperarioId: Integer;
  const CodHab: string): string;
begin
  Result := IntToStr(OperarioId) + '#' + UpperCase(Trim(CodHab));
end;

procedure TfrmMatrizPolivalencia.LoadData;
var
  I: Integer;
  OH: TArray<TOperarioHabilidad>;
  Op: TOperario;
begin
  FNivel.Clear;
  if FOperariosRepo <> nil then
    FOperarios := FOperariosRepo.GetOperarios
  else
    SetLength(FOperarios, 0);

  if FHabRepo <> nil then
    FHabilidades := FHabRepo.GetHabilidades
  else
    SetLength(FHabilidades, 0);

  // Cargar nivel por operario
  if FHabRepo <> nil then
    for Op in FOperarios do
    begin
      OH := FHabRepo.GetHabilidadesOperario(Op.Id);
      for I := 0 to High(OH) do
        FNivel.AddOrSetValue(KeyFor(Op.Id, OH[I].CodHabilidad),
          Integer(OH[I].Nivel));
    end;

  // Ajustar tamano del PaintBox para que el ScrollBox sepa cuanto scroll dar
  ComputeMatrixSize(I, I); // dummy, llamamos al de verdad despues
  FormResize(nil);
  pbMatrix.Invalidate;
  pbLegend.Invalidate;
end;

function TfrmMatrizPolivalencia.GetNivel(OperarioId: Integer;
  const CodHab: string; out Found: Boolean): TNivelSkill;
var
  V: Integer;
begin
  Result := nsAprendiz;
  Found := FNivel.TryGetValue(KeyFor(OperarioId, CodHab), V);
  if Found then
    Result := TinyIntToNivelSkill(V);
end;

procedure TfrmMatrizPolivalencia.ComputeMatrixSize(out AWidth, AHeight: Integer);
var
  NumHab, NumOp, TempW, TempH: Integer;
begin
  NumHab := Length(FHabilidades);
  NumOp := Length(FOperarios);
  TempW := NumHab * CELL_W;
  TempW := TempW + ROW_LABEL_W;
  TempW := TempW + MTX_PADDING;
  TempH := NumOp * CELL_H;
  TempH := TempH + COL_HEADER_H;
  TempH := TempH + MTX_PADDING;
  AWidth := TempW;
  AHeight := TempH;
  if AWidth < sbMatrix.ClientWidth then AWidth := sbMatrix.ClientWidth;
  if AHeight < sbMatrix.ClientHeight then AHeight := sbMatrix.ClientHeight;
end;

procedure TfrmMatrizPolivalencia.FormResize(Sender: TObject);
var
  W, H: Integer;
begin
  ComputeMatrixSize(W, H);
  pbMatrix.SetBounds(0, 0, W, H);
end;

procedure TfrmMatrizPolivalencia.pbLegendPaint(Sender: TObject);
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
    if ATextDark then TxColor := CLR_TEXT_LIGHT else TxColor := CLR_TEXT_DARK;
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
  // Fondo
  C.Brush.Color := CLR_PAPER;
  C.FillRect(pbLegend.ClientRect);

  BoxW := 100;
  BoxH := pbLegend.Height - 4;
  Gap  := 8;
  X    := 4;
  Y    := 2;

  Chip(CLR_NO_SKILL, 'No formado', True);
  Chip(CLR_APRENDIZ, 'Aprendiz',   True);
  Chip(CLR_JUNIOR,   'Junior',     False);
  Chip(CLR_SENIOR,   'Senior',     False);
  Chip(CLR_EXPERTO,  'Experto',    False);
end;

procedure TfrmMatrizPolivalencia.pbMatrixPaint(Sender: TObject);
var
  C: TCanvas;
  I, J, X, Y: Integer;
  R: TRect;
  Nivel: TNivelSkill;
  Found: Boolean;
  BgColor, TxColor: TColor;
  Lbl: string;
  TextDark: Boolean;
begin
  C := pbMatrix.Canvas;
  C.Font.Name := 'Segoe UI';

  // Fondo
  C.Brush.Color := CLR_PAPER;
  C.FillRect(pbMatrix.ClientRect);

  if (Length(FOperarios) = 0) or (Length(FHabilidades) = 0) then
  begin
    C.Font.Size := 10;
    C.Font.Color := CLR_TEXT_LIGHT;
    C.Brush.Style := bsClear;
    R := pbMatrix.ClientRect;
    DrawText(C.Handle,
      PChar('No hay operarios o habilidades en el cat'#225'logo.'),
      -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Exit;
  end;

  // ----- Cabecera de columnas (habilidades) -----
  C.Font.Size := 9;
  C.Font.Style := [fsBold];
  C.Brush.Color := CLR_HEADER_BG;
  R := Rect(ROW_LABEL_W, 0, ROW_LABEL_W + Length(FHabilidades) * CELL_W, COL_HEADER_H);
  C.FillRect(R);

  for J := 0 to High(FHabilidades) do
  begin
    X := ROW_LABEL_W + J * CELL_W;
    R := Rect(X, 0, X + CELL_W, COL_HEADER_H);
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    // Codigo + descripcion en 2 lineas
    Lbl := FHabilidades[J].Codigo;
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    C.Brush.Style := bsSolid;
  end;

  // ----- Columna de operarios (nombres) -----
  C.Brush.Color := CLR_HEADER_BG;
  R := Rect(0, COL_HEADER_H, ROW_LABEL_W, COL_HEADER_H + Length(FOperarios) * CELL_H);
  C.FillRect(R);

  for I := 0 to High(FOperarios) do
  begin
    Y := COL_HEADER_H + I * CELL_H;
    R := Rect(8, Y, ROW_LABEL_W - 8, Y + CELL_H);
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(FOperarios[I].Nombre), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    C.Brush.Style := bsSolid;
  end;

  // ----- Cuadradito vacio en esquina superior izquierda -----
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, ROW_LABEL_W, COL_HEADER_H));

  // ----- Celdas de la matriz -----
  C.Font.Style := [fsBold];
  C.Font.Size := 9;
  for I := 0 to High(FOperarios) do
    for J := 0 to High(FHabilidades) do
    begin
      X := ROW_LABEL_W + J * CELL_W;
      Y := COL_HEADER_H + I * CELL_H;
      R := Rect(X + 2, Y + 2, X + CELL_W - 2, Y + CELL_H - 2);

      Nivel := GetNivel(FOperarios[I].Id, FHabilidades[J].Codigo, Found);
      if not Found then
      begin
        BgColor  := CLR_NO_SKILL;
        TxColor  := CLR_TEXT_LIGHT;
        Lbl      := string(#8212); // em dash, mismo glifo que el doc
        TextDark := True;
      end
      else
      begin
        case Nivel of
          nsAprendiz: begin BgColor := CLR_APRENDIZ; TextDark := True;  Lbl := 'Apr.'; end;
          nsJunior:   begin BgColor := CLR_JUNIOR;   TextDark := False; Lbl := 'Jr.';  end;
          nsSenior:   begin BgColor := CLR_SENIOR;   TextDark := False; Lbl := 'Sr.';  end;
          nsExperto:  begin BgColor := CLR_EXPERTO;  TextDark := False; Lbl := 'Exp.'; end;
        else
          BgColor := CLR_NO_SKILL; TextDark := True; Lbl := '?';
        end;
        if TextDark then TxColor := CLR_TEXT_LIGHT else TxColor := CLR_TEXT_DARK;
      end;

      C.Brush.Color := BgColor;
      C.FillRect(R);

      C.Font.Color := TxColor;
      C.Brush.Style := bsClear;
      DrawText(C.Handle, PChar(Lbl), -1, R,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      C.Brush.Style := bsSolid;
    end;

  // ----- L'ineas de grid sutiles -----
  C.Pen.Color := CLR_GRID_LINE;
  C.Pen.Style := psSolid;
  for J := 0 to Length(FHabilidades) do
  begin
    X := ROW_LABEL_W + J * CELL_W;
    C.MoveTo(X, 0);
    C.LineTo(X, COL_HEADER_H + Length(FOperarios) * CELL_H);
  end;
  for I := 0 to Length(FOperarios) do
  begin
    Y := COL_HEADER_H + I * CELL_H;
    C.MoveTo(0, Y);
    C.LineTo(ROW_LABEL_W + Length(FHabilidades) * CELL_W, Y);
  end;
end;

end.
