unit uBusyDialog;

// ============================================================================
// Form modal-less reutilizable para dar feedback de "Cargando..." al usuario
// durante operaciones bloqueantes en el thread principal (queries SQL,
// importaciones, etc.).
//
// Uso tipico:
//
//   var Busy := TfrmBusyDialog.Display(Self, 'Cargando datos...');
//   try
//     // ... operacion lenta sincrona ...
//   finally
//     Busy.Free;
//   end;
//
// O bien con el helper:
//
//   ShowBusy(Self, 'Cargando datos...',
//     procedure
//     begin
//       LoadData;
//     end);
//
// El form NO usa thread secundario: se pinta antes de la operacion lenta y se
// libera al final. La barra de progreso indeterminada se anima por TTimer; se
// movera siempre que el bucle de mensajes reciba turnos (ADO suele cederlos).
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Winapi.GDIPOBJ, Winapi.GDIPAPI;

type
  TfrmBusyDialog = class(TForm)
    pnlBorder: TPanel;
    lblMessage: TLabel;
    lblSub: TLabel;
    pbSpinner: TPaintBox;
    procedure pbSpinnerPaint(Sender: TObject);
  private
    FOldCursor: TCursor;
    FTimer: TTimer;
    FAngle: Single;        // angulo de rotacion del spinner (grados)
    procedure OnTick(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    class function Display(AOwner: TForm; const AMessage: string): TfrmBusyDialog;
    procedure UpdateMessage(const AMessage: string);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

procedure ShowBusy(AOwner: TForm; const AMessage: string; AProc: TProc);

// Ejecuta AWork en un thread secundario (con CoInitialize, apto para ADO con
// conexion propia) mientras el dialogo anima el spinner en el hilo principal.
// AWork NO debe tocar controles VCL ni la conexion ADO compartida: solo trabajo
// de fondo (p.ej. abrir una query client-side y desconectarla). El resultado se
// procesa despues, ya de vuelta en el hilo principal, por el llamador.
procedure RunBusy(AOwner: TForm; const AMessage: string; AWork: TProc);

implementation

{$R *.dfm}

const
  CS_DROPSHADOW = $00020000;
  // Color corporativo del header (3553567 = $00364C1F en BGR).
  AccentR = $1F;
  AccentG = $4C;
  AccentB = $36;
  TrackAlpha = 40;    // opacidad de la pista de fondo del anillo
  SweepDeg   = 270;   // arco abierto, como el icono loader-4-line de RemixIcon
  StepDeg    = 12;    // grados que gira por tick (velocidad)

procedure TfrmBusyDialog.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Sombra suave bajo la tarjeta (efecto card flotante moderno).
  Params.WindowClass.Style := Params.WindowClass.Style or CS_DROPSHADOW;
end;

constructor TfrmBusyDialog.Create(AOwner: TComponent);
begin
  inherited;
  // Siempre centrado en la PANTALLA (no en el owner, que puede estar
  // descentrado o embebido).
  Position := poScreenCenter;
  FAngle := 0;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 30;
  FTimer.OnTimer := OnTick;
  FTimer.Enabled := False;
end;

procedure TfrmBusyDialog.OnTick(Sender: TObject);
begin
  FAngle := FAngle + StepDeg;
  if FAngle >= 360 then FAngle := FAngle - 360;
  // Pintar directamente (sin Invalidate) para no disparar el borrado de fondo
  // del control, que es lo que produce flicker. El propio Paint ya repinta todo
  // el area con double buffering.
  pbSpinnerPaint(pbSpinner);
end;

procedure TfrmBusyDialog.pbSpinnerPaint(Sender: TObject);
var
  Buf: TBitmap;
  G: TGPGraphics;
  Pen: TGPPen;
  W, H: Integer;
  Margin, PenW, FW, FH: Single;
begin
  W := pbSpinner.Width;
  H := pbSpinner.Height;
  PenW := 5;
  Margin := PenW;  // dejar sitio para el grosor del trazo
  FW := W;
  FH := H;

  // Double buffering: se pinta todo (fondo + anillo + arco) en un bitmap en
  // memoria y se vuelca de una sola vez. Evita el parpadeo (flicker) que produce
  // pintar fondo y arco por separado directamente sobre el control.
  Buf := TBitmap.Create;
  try
    Buf.SetSize(W, H);

    // Fondo blanco (mismo color de la tarjeta) para que el anillo no deje rastro.
    Buf.Canvas.Brush.Color := clWhite;
    Buf.Canvas.FillRect(Rect(0, 0, W, H));

    G := TGPGraphics.Create(Buf.Canvas.Handle);
    try
      G.SetSmoothingMode(SmoothingModeAntiAlias);

      // Pista de fondo: anillo completo tenue (mismo color, semitransparente).
      Pen := TGPPen.Create(MakeColor(TrackAlpha, AccentR, AccentG, AccentB), PenW);
      try
        Pen.SetStartCap(LineCapRound);
        Pen.SetEndCap(LineCapRound);
        G.DrawArc(Pen, Margin, Margin, FW - 2*Margin, FH - 2*Margin, 0, 360);
      finally
        Pen.Free;
      end;

      // Arco activo (loader-4-line): 270 grados, girando con FAngle.
      Pen := TGPPen.Create(MakeColor(255, AccentR, AccentG, AccentB), PenW);
      try
        Pen.SetStartCap(LineCapRound);
        Pen.SetEndCap(LineCapRound);
        G.DrawArc(Pen, Margin, Margin, FW - 2*Margin, FH - 2*Margin,
          FAngle, SweepDeg);
      finally
        Pen.Free;
      end;
    finally
      G.Free;
    end;

    pbSpinner.Canvas.Draw(0, 0, Buf);
  finally
    Buf.Free;
  end;
end;

class function TfrmBusyDialog.Display(AOwner: TForm;
  const AMessage: string): TfrmBusyDialog;
begin
  Result := TfrmBusyDialog.Create(AOwner);
  Result.lblMessage.Caption := AMessage;
  Result.FOldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  // Show no-modal: el form aparece pero no bloquea al thread principal.
  Result.Show;
  Result.FTimer.Enabled := True;
  // Forzar pintado completo antes de devolver el control.
  Result.Update;
  Application.ProcessMessages;
end;

procedure TfrmBusyDialog.UpdateMessage(const AMessage: string);
begin
  lblMessage.Caption := AMessage;
  Update;
  Application.ProcessMessages;
end;

destructor TfrmBusyDialog.Destroy;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := False;
  Screen.Cursor := FOldCursor;
  inherited;
end;

procedure ShowBusy(AOwner: TForm; const AMessage: string; AProc: TProc);
var
  Busy: TfrmBusyDialog;
begin
  Busy := TfrmBusyDialog.Display(AOwner, AMessage);
  try
    AProc();
  finally
    Busy.Free;
  end;
end;

procedure RunBusy(AOwner: TForm; const AMessage: string; AWork: TProc);
var
  Busy: TfrmBusyDialog;
  Done: Boolean;
  WorkErr: string;
begin
  Busy := TfrmBusyDialog.Display(AOwner, AMessage);
  Done := False;
  WorkErr := '';
  try
    TThread.CreateAnonymousThread(
      procedure
      begin
        // ADO en thread propio requiere COM inicializado en este hilo.
        CoInitialize(nil);
        try
          try
            AWork();
          except
            on E: Exception do
              WorkErr := E.Message;
          end;
        finally
          CoUninitialize;
          Done := True;   // bandera simple; el hilo principal hace polling.
        end;
      end).Start;

    // El hilo principal sigue libre: el TTimer anima el spinner con fluidez.
    // Sleep breve para no quemar CPU mientras el thread trabaja.
    while not Done do
    begin
      Application.ProcessMessages;
      Sleep(5);
    end;
  finally
    Busy.Free;
  end;

  if WorkErr <> '' then
    raise Exception.Create(WorkErr);
end;

end.
