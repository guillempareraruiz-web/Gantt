unit uNesting2DPoligonoEditor;

{ ============================================================================
  Editor de POLIGONO LIBRE para el modulo de nesting 2D.

  Dialogo modal donde el usuario introduce los vertices (X, Y en mm) de un
  contorno cerrado en una rejilla, con vista previa GDI+ en vivo. Devuelve el
  TPolygon2D resultante.

  Entrada:  EditarPoligono2D(AOwner, out APoly): Boolean;
  ============================================================================ }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Math, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  cxGraphics, cxControls, cxLookAndFeels, cxContainer, cxEdit, cxStyles,
  cxClasses, cxGrid, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxButtons, cxTextEdit,
  uNesting2DTypes;

type
  TfrmPoligonoEditor = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlLeft: TPanel;
    gridPuntos: TcxGrid;
    tvPuntos: TcxGridTableView;
    colX: TcxGridColumn;
    colY: TcxGridColumn;
    lvPuntos: TcxGridLevel;
    btnAddPunto: TcxButton;
    btnDelPunto: TcxButton;
    pnlPreview: TPanel;
    pbPreview: TPaintBox;
    pnlFooter: TPanel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAddPuntoClick(Sender: TObject);
    procedure btnDelPuntoClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure pbPreviewPaint(Sender: TObject);
    procedure tvPuntosDataControllerAfterPost(ADataController: TObject);
  private
    function ReadPolygon: TPolygon2D;
    procedure AddPoint(AX, AY: Double);
  public
    ResultPoly: TPolygon2D;
  end;

function EditarPoligono2D(AOwner: TForm; out APoly: TPolygon2D): Boolean;

implementation

{$R *.dfm}

function EditarPoligono2D(AOwner: TForm; out APoly: TPolygon2D): Boolean;
var
  F: TfrmPoligonoEditor;
begin
  Result := False;
  F := TfrmPoligonoEditor.Create(AOwner);
  try
    if F.ShowModal <> mrOk then Exit;
    APoly := F.ResultPoly;
    Result := APoly.Count >= 3;
  finally
    F.Free;
  end;
end;

procedure TfrmPoligonoEditor.FormCreate(Sender: TObject);
begin
  // Ejemplo de partida: un triangulo, para que el usuario vea el formato.
  AddPoint(0, 0);
  AddPoint(100, 0);
  AddPoint(50, 80);
end;

procedure TfrmPoligonoEditor.AddPoint(AX, AY: Double);
var
  I: Integer;
begin
  I := tvPuntos.DataController.RecordCount;
  tvPuntos.DataController.RecordCount := I + 1;
  tvPuntos.DataController.Values[I, colX.Index] := AX;
  tvPuntos.DataController.Values[I, colY.Index] := AY;
end;

procedure TfrmPoligonoEditor.btnAddPuntoClick(Sender: TObject);
begin
  AddPoint(0, 0);
  pbPreview.Invalidate;
end;

procedure TfrmPoligonoEditor.btnDelPuntoClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := tvPuntos.Controller.FocusedRecordIndex;
  if (Idx >= 0) and (Idx < tvPuntos.DataController.RecordCount) then
  begin
    tvPuntos.DataController.DeleteRecord(Idx);
    pbPreview.Invalidate;
  end;
end;

procedure TfrmPoligonoEditor.tvPuntosDataControllerAfterPost(
  ADataController: TObject);
begin
  pbPreview.Invalidate;
end;

function TfrmPoligonoEditor.ReadPolygon: TPolygon2D;
var
  I, N: Integer;
  L: TList<TPt2D>;
  VX, VY: Variant;
begin
  N := tvPuntos.DataController.RecordCount;
  L := TList<TPt2D>.Create;
  try
    for I := 0 to N - 1 do
    begin
      VX := tvPuntos.DataController.Values[I, colX.Index];
      VY := tvPuntos.DataController.Values[I, colY.Index];
      if VarIsNull(VX) or VarIsEmpty(VX) then VX := 0;
      if VarIsNull(VY) or VarIsEmpty(VY) then VY := 0;
      L.Add(TPt2D.Make(VX, VY));
    end;
    Result.Pts := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmPoligonoEditor.btnAceptarClick(Sender: TObject);
var
  Poly: TPolygon2D;
begin
  Poly := ReadPolygon;
  if Poly.Count < 3 then
  begin
    ShowMessage('Un pol'#237'gono necesita al menos 3 v'#233'rtices.');
    Exit;
  end;
  if Poly.Area <= 0 then
  begin
    ShowMessage('El pol'#237'gono tiene '#225'rea nula (v'#233'rtices alineados o repetidos).');
    Exit;
  end;
  ResultPoly := Poly;
  ModalResult := mrOk;
end;

procedure TfrmPoligonoEditor.pbPreviewPaint(Sender: TObject);
var
  Buf: TBitmap;
  G: TGPGraphics;
  Poly: TPolygon2D;
  B: TBBox;
  Scale, Margin, OffX, OffY: Double;
  I, N, W, H: Integer;
  pts: array of TGPPointF;
  Brush: TGPSolidBrush;
  Pen: TGPPen;
begin
  W := pbPreview.Width;
  H := pbPreview.Height;
  Buf := TBitmap.Create;
  try
    Buf.PixelFormat := pf24bit;
    Buf.SetSize(W, H);
    Buf.Canvas.Brush.Color := clWhite;
    Buf.Canvas.FillRect(Rect(0, 0, W, H));

    Poly := ReadPolygon;
    N := Poly.Count;
    if N >= 3 then
    begin
      B := Poly.BBox;
      Margin := 12;
      Scale := Min((W - 2 * Margin) / Max(1, B.Width),
                   (H - 2 * Margin) / Max(1, B.Height));
      if Scale <= 0 then Scale := 1;
      OffX := Margin - B.MinX * Scale;
      OffY := Margin - B.MinY * Scale;

      SetLength(pts, N);
      for I := 0 to N - 1 do
        pts[I] := MakePoint(
          Single(OffX + Poly.Pts[I].X * Scale),
          Single(H - (OffY + Poly.Pts[I].Y * Scale)));  // Y invertida

      G := TGPGraphics.Create(Buf.Canvas.Handle);
      try
        G.SetSmoothingMode(SmoothingModeAntiAlias);
        Brush := TGPSolidBrush.Create(MakeColor(200, 78, 121, 167));
        Pen := TGPPen.Create(MakeColor(255, 40, 40, 40), 1.4);
        try
          G.FillPolygon(Brush, PGPPointF(@pts[0]), N);
          G.DrawPolygon(Pen, PGPPointF(@pts[0]), N);
        finally
          Brush.Free;
          Pen.Free;
        end;
      finally
        G.Free;
      end;
    end
    else
    begin
      Buf.Canvas.Font.Color := clGray;
      Buf.Canvas.TextOut(10, 10, 'A'#241'ade al menos 3 v'#233'rtices.');
    end;

    pbPreview.Canvas.Draw(0, 0, Buf);
  finally
    Buf.Free;
  end;
end;

end.
