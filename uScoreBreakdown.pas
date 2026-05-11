unit uScoreBreakdown;

{
  TfrmScoreBreakdown - Di'alogo modal para mostrar el desglose del scoring
  de una asignacion del motor de planificacion automatica.

  Muestra los 7 componentes (Prioridad, Compromiso, Nivel, Carga,
  Continuidad, Espera, Coste) con valor numerico, barra proporcional al
  peso del componente sobre el total positivo, y datos auxiliares
  (sobrenivel, carga actual, dias a compromiso, etc).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  uPlanProdTypes;

type
  TBreakdownPanel = class(TPanel)
  private
    FBreakdown: TScoreBreakdown;
    procedure WMEraseBkgnd(var Msg: TMessage); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure DrawRow(Y: Integer; const ALabel: string; AValue: Double;
      AMaxAbs: Double; const AHelp: string);
  public
    procedure SetBreakdown(const A: TScoreBreakdown);
  end;

  TfrmScoreBreakdown = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlHost: TPanel;
    pnlBottom: TPanel;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
  private
    FBody: TBreakdownPanel;
  public
    class procedure Execute(const ABreakdown: TScoreBreakdown);
  end;

implementation

{$R *.dfm}

function YesNoText(Cond: Boolean; const A, B: string): string;
begin
  if Cond then Result := A else Result := B;
end;

{ TBreakdownPanel }

procedure TBreakdownPanel.WMEraseBkgnd(var Msg: TMessage);
begin
  Msg.Result := 1;
end;

procedure TBreakdownPanel.SetBreakdown(const A: TScoreBreakdown);
begin
  FBreakdown := A;
  Invalidate;
end;

procedure TBreakdownPanel.DrawRow(Y: Integer; const ALabel: string;
  AValue, AMaxAbs: Double; const AHelp: string);
var
  BarLeft, BarRight, BarMid, BarPx, BarH: Integer;
  Col: TColor;
  R: TRect;
begin
  // Etiqueta
  Canvas.Font.Name := 'Segoe UI Semibold';
  Canvas.Font.Size := 9;
  Canvas.Font.Color := $00303030;
  Canvas.Font.Style := [fsBold];
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(20, Y, ALabel);

  // Help text
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 8;
  Canvas.Font.Color := $00808080;
  Canvas.Font.Style := [];
  Canvas.TextOut(20, Y + 18, AHelp);

  // Valor numerico
  Canvas.Font.Name := 'Consolas';
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [fsBold];
  if AValue >= 0 then
    Canvas.Font.Color := $00208030
  else
    Canvas.Font.Color := $002020E0;
  Canvas.TextOut(ClientWidth - 110, Y, Format('%+.2f', [AValue]));

  // Barra proporcional
  BarLeft := 20;
  BarRight := ClientWidth - 130;
  BarMid := (BarLeft + BarRight) div 2;
  BarH := 6;

  Canvas.Pen.Color := $00E0E0E0;
  Canvas.Brush.Color := $00F4F4F0;
  R := Rect(BarLeft, Y + 30, BarRight, Y + 30 + BarH);
  Canvas.FillRect(R);
  Canvas.MoveTo(BarMid, Y + 30);
  Canvas.LineTo(BarMid, Y + 30 + BarH);

  if AMaxAbs > 0 then
  begin
    BarPx := Round((AValue / AMaxAbs) * ((BarRight - BarLeft) / 2));
    if AValue >= 0 then
      Col := $00208030
    else
      Col := $002020E0;
    Canvas.Brush.Color := Col;
    if AValue >= 0 then
      Canvas.FillRect(Rect(BarMid, Y + 30, BarMid + BarPx, Y + 30 + BarH))
    else
      Canvas.FillRect(Rect(BarMid + BarPx, Y + 30, BarMid, Y + 30 + BarH));
  end;
  Canvas.Brush.Style := bsSolid;
end;

procedure TBreakdownPanel.Paint;
var
  MaxAbs: Double;
begin
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ClientRect);
  Canvas.Font.Quality := fqClearTypeNatural;

  MaxAbs := 1;
  MaxAbs := Max(MaxAbs, Abs(FBreakdown.AportPrioridad));
  MaxAbs := Max(MaxAbs, Abs(FBreakdown.AportCompromiso));
  MaxAbs := Max(MaxAbs, Abs(FBreakdown.AportNivelCompetencia));
  MaxAbs := Max(MaxAbs, Abs(FBreakdown.AportCarga));
  MaxAbs := Max(MaxAbs, Abs(FBreakdown.AportContinuidad));
  MaxAbs := Max(MaxAbs, Abs(FBreakdown.AportEspera));
  MaxAbs := Max(MaxAbs, Abs(FBreakdown.AportCoste));

  DrawRow(20,  '1. Prioridad orden',
    FBreakdown.AportPrioridad, MaxAbs,
    Format('Prioridad del nodo: %d', [FBreakdown.PrioridadNode]));

  DrawRow(60,  '2. Compromiso (deadline)',
    FBreakdown.AportCompromiso, MaxAbs,
    Format('D'#237'as a fecha entrega: %.1f', [FBreakdown.DiasACompromiso]));

  DrawRow(100, '3. Nivel competencia / fit',
    FBreakdown.AportNivelCompetencia, MaxAbs,
    Format('Sobrenivel: %d (cuanto m'#225's, menos puntos)',
      [FBreakdown.Sobrenivel]));

  DrawRow(140, '4. Carga jornada',
    FBreakdown.AportCarga, MaxAbs,
    Format('Horas asignadas en este batch: %.2f h',
      [FBreakdown.CargaActualOp]));

  DrawRow(180, '5. Continuidad (misma OF)',
    FBreakdown.AportContinuidad, MaxAbs,
    YesNoText(FBreakdown.HasContinuidadOF,
      'Operario ya asignado a otra operaci'#243'n de la misma OF: bonifica',
      'Sin asignaciones previas a la misma OF'));

  DrawRow(220, '6. Espera (anti-starvation)',
    FBreakdown.AportEspera, MaxAbs,
    Format('D'#237'as desde fecha necesaria: %.1f', [FBreakdown.DiasEspera]));

  DrawRow(260, '7. Coste mano de obra',
    FBreakdown.AportCoste, MaxAbs,
    Format('%.2f EUR/h efectivo (sueldo + recargos)',
      [FBreakdown.CosteEurHora]));

  // Linea total
  Canvas.Pen.Color := $00C0C0C0;
  Canvas.MoveTo(16, 305);
  Canvas.LineTo(ClientWidth - 16, 305);

  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Size := 11;
  Canvas.Font.Color := $00303030;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(20, 315, 'TOTAL');
  Canvas.TextOut(ClientWidth - 120, 315,
    Format('%.2f puntos', [FBreakdown.Total]));
  Canvas.Brush.Style := bsSolid;
end;

{ TfrmScoreBreakdown }

class procedure TfrmScoreBreakdown.Execute(const ABreakdown: TScoreBreakdown);
var
  F: TfrmScoreBreakdown;
begin
  F := TfrmScoreBreakdown.Create(nil);
  try
    F.lblTitle.Caption := Format('Por qu'#233' %s para Node #%d',
      [ABreakdown.OperarioNombre, ABreakdown.NodeDataId]);
    F.lblSubtitle.Caption := Format(
      'Operaci'#243'n: %s    Score total: %.2f',
      [ABreakdown.Operacion, ABreakdown.Total]);
    F.FBody.SetBreakdown(ABreakdown);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmScoreBreakdown.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  FBody := TBreakdownPanel.Create(Self);
  FBody.Parent := pnlHost;
  FBody.Align := alClient;
  FBody.BevelOuter := bvNone;
  FBody.DoubleBuffered := True;
end;

end.
