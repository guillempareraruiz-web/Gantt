unit uModulosConfig;

{
  Pantalla de MODULOS CONTRATADOS.

  La usa FactoryStart (o el administrador) para decir que partes del Planner
  entran en la licencia de esta empresa. No es una pantalla de uso diario: se
  toca al instalar y cuando el cliente amplia.

  Diseno: una TARJETA por modulo, no una rejilla de casillas. Aqui no se marcan
  opciones sueltas, se decide que compra un cliente, y cada decision necesita
  su nombre comercial, que incluye y desde cuando caduca. Una rejilla obligaria
  a saberselo de memoria.

  Las tarjetas se crean por codigo porque su NUMERO depende del catalogo de
  uModulos: anadir un modulo alli debe bastar para que aparezca aqui, sin tocar
  el .dfm.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Dialogs,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxButtons, cxCheckBox, cxTextEdit,
  cxContainer, cxMaskEdit, cxDropDownEdit, cxCalendar,
  dxSkinsCore, dxSkinsDefaultPainters,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uModulos;

type
  // Icono + indicador de estado de un modulo, dibujado con GDI+.
  //
  // Se pinta en vez de usar imagenes por dos razones: no hay que mantener un
  // ImageList paralelo al catalogo de modulos (anadir un modulo en uModulos
  // basta), y el mismo control sirve de semaforo — el anillo exterior dice si
  // esta contratado sin tener que leer la casilla.
  TModuloIcono = class(TCustomControl)
  private
    FCodigo: string;
    FActivo: Boolean;
    procedure SetActivo(const V: Boolean);
    procedure SetCodigo(const V: string);
    // Cada modulo tiene su glifo: se reconoce antes de leer el nombre.
    procedure DibujarGlifo(G: TGPGraphics; CX, CY, R: Single; AColor: Cardinal);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Codigo: string read FCodigo write SetCodigo;
    property Activo: Boolean read FActivo write SetActivo;
  end;

  TfrmModulosConfig = class(TForm)
    pnlHeader: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlNucleo: TPanel;
    lblNucleo: TLabel;
    lblNucleoDet: TLabel;
    pnlBottom: TPanel;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    lblAviso: TLabel;
    sbModulos: TScrollBox;
  private
    FModulos: TModuloInfoArray;
    // Controles de cada tarjeta, en el mismo orden que FModulos.
    FChks: TList<TcxCheckBox>;
    FFechas: TList<TcxDateEdit>;
    FObs: TList<TcxTextEdit>;
    FIconos: TList<TModuloIcono>;

    procedure ConstruirTarjetas;
    procedure RecogerCambios;
    procedure ActualizarAviso(Sender: TObject);
  public
    class function Execute: Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uHelpViewer;

const
  MARGEN = 16;
  ALTO_TARJETA = 92;
  SEP = 10;

  COL_BORDE   = $00E0DCD8;
  // TColor es BGR, al reves que el hexadecimal habitual.
  COL_ON      = $00E9F5E8;   // verde muy suave: contratado
  COL_OFF     = $00ECF0FA;   // terracota muy suave: no contratado
  // Terracota y no rojo: un modulo no contratado no es un error (ver Paint
  // del icono para el razonamiento completo).

{ TModuloIcono }

constructor TModuloIcono.Create(AOwner: TComponent);
begin
  inherited;
  Width := 44;
  Height := 44;
  FActivo := True;
  // El fondo lo pone la tarjeta: este control solo dibuja encima.
  ControlStyle := ControlStyle - [csOpaque];
end;

procedure TModuloIcono.SetActivo(const V: Boolean);
begin
  if FActivo = V then Exit;
  FActivo := V;
  Invalidate;
end;

procedure TModuloIcono.SetCodigo(const V: string);
begin
  if FCodigo = V then Exit;
  FCodigo := V;
  Invalidate;
end;

procedure TModuloIcono.DibujarGlifo(G: TGPGraphics; CX, CY, R: Single;
  AColor: Cardinal);
var
  P: TGPPen;
  B: TGPSolidBrush;
  S: Single;
  // Vertices del rayo (glifo de OPTIMIZACION). Se declara aqui y no inline:
  // Delphi 11 no admite "var X: array[...]" dentro del cuerpo.
  Pts: array[0..6] of TGPPointF;
begin
  // Trazos, no relleno: a este tamano un glifo lineal se lee mucho mejor que
  // una silueta maciza, y envejece mejor que un icono de moda.
  P := TGPPen.Create(AColor, 1.8);
  B := TGPSolidBrush.Create(AColor);
  try
    P.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
    S := R * 0.62;   // media caja del glifo

    if FCodigo = MOD_OPERARIOS then
    begin
      // Persona: cabeza + hombros.
      G.DrawEllipse(P, CX - S * 0.30, CY - S * 0.85, S * 0.60, S * 0.60);
      G.DrawArc(P, CX - S * 0.70, CY - S * 0.10, S * 1.40, S * 1.40,
        200, 140);
    end
    else if FCodigo = MOD_INGENIERIA then
    begin
      // Estructura WBS: un nodo padre y dos hijos.
      G.DrawRectangle(P, CX - S * 0.28, CY - S * 0.90, S * 0.56, S * 0.42);
      G.DrawLine(P, CX, CY - S * 0.48, CX, CY - S * 0.10);
      G.DrawLine(P, CX - S * 0.55, CY - S * 0.10, CX + S * 0.55, CY - S * 0.10);
      G.DrawLine(P, CX - S * 0.55, CY - S * 0.10, CX - S * 0.55, CY + S * 0.20);
      G.DrawLine(P, CX + S * 0.55, CY - S * 0.10, CX + S * 0.55, CY + S * 0.20);
      G.DrawRectangle(P, CX - S * 0.85, CY + S * 0.20, S * 0.60, S * 0.40);
      G.DrawRectangle(P, CX + S * 0.25, CY + S * 0.20, S * 0.60, S * 0.40);
    end
    else if FCodigo = MOD_MRP then
    begin
      // Caja de almacen (isometrica simple).
      G.DrawLine(P, CX - S * 0.85, CY - S * 0.35, CX, CY - S * 0.80);
      G.DrawLine(P, CX, CY - S * 0.80, CX + S * 0.85, CY - S * 0.35);
      G.DrawLine(P, CX - S * 0.85, CY - S * 0.35, CX - S * 0.85, CY + S * 0.55);
      G.DrawLine(P, CX + S * 0.85, CY - S * 0.35, CX + S * 0.85, CY + S * 0.55);
      G.DrawLine(P, CX - S * 0.85, CY + S * 0.55, CX, CY + S * 0.95);
      G.DrawLine(P, CX + S * 0.85, CY + S * 0.55, CX, CY + S * 0.95);
      G.DrawLine(P, CX, CY - S * 0.80, CX, CY + S * 0.95);
      G.DrawLine(P, CX - S * 0.85, CY - S * 0.35, CX, CY + S * 0.10);
      G.DrawLine(P, CX + S * 0.85, CY - S * 0.35, CX, CY + S * 0.10);
    end
    else if FCodigo = MOD_UTILLAJES then
    begin
      // Llave / util: circulo con dientes.
      G.DrawEllipse(P, CX - S * 0.55, CY - S * 0.55, S * 1.10, S * 1.10);
      G.DrawEllipse(P, CX - S * 0.18, CY - S * 0.18, S * 0.36, S * 0.36);
      G.DrawLine(P, CX, CY - S * 0.95, CX, CY - S * 0.55);
      G.DrawLine(P, CX, CY + S * 0.55, CX, CY + S * 0.95);
      G.DrawLine(P, CX - S * 0.95, CY, CX - S * 0.55, CY);
      G.DrawLine(P, CX + S * 0.55, CY, CX + S * 0.95, CY);
    end
    else if FCodigo = MOD_OPTIMIZACION then
    begin
      // Rayo: el motor que reordena. El ultimo punto repite el primero para
      // cerrar la silueta.
      Pts[0] := MakePoint(CX + S * 0.20, CY - S * 0.95);
      Pts[1] := MakePoint(CX - S * 0.55, CY + S * 0.10);
      Pts[2] := MakePoint(CX - S * 0.05, CY + S * 0.10);
      Pts[3] := MakePoint(CX - S * 0.20, CY + S * 0.95);
      Pts[4] := MakePoint(CX + S * 0.55, CY - S * 0.10);
      Pts[5] := MakePoint(CX + S * 0.05, CY - S * 0.10);
      Pts[6] := Pts[0];
      G.DrawPolygon(P, PGPPointF(@Pts[0]), 7);
    end
    else if FCodigo = MOD_ANALITICA then
    begin
      // Barras de un grafico, de menor a mayor.
      G.DrawLine(P, CX - S * 0.90, CY + S * 0.85, CX + S * 0.90, CY + S * 0.85);
      G.FillRectangle(B, CX - S * 0.70, CY + S * 0.15, S * 0.34, S * 0.70);
      G.FillRectangle(B, CX - S * 0.17, CY - S * 0.35, S * 0.34, S * 1.20);
      G.FillRectangle(B, CX + S * 0.36, CY - S * 0.80, S * 0.34, S * 1.65);
    end
    else if FCodigo = MOD_NESTING then
    begin
      // Piezas anidadas en una plancha.
      G.DrawRectangle(P, CX - S * 0.90, CY - S * 0.80, S * 1.80, S * 1.60);
      G.DrawRectangle(P, CX - S * 0.70, CY - S * 0.60, S * 0.75, S * 0.75);
      G.DrawEllipse(P, CX + S * 0.15, CY - S * 0.55, S * 0.60, S * 0.60);
      G.DrawRectangle(P, CX - S * 0.55, CY + S * 0.25, S * 1.15, S * 0.35);
    end
    else
      // Modulo desconocido (catalogo mas nuevo que este control): punto neutro.
      G.FillEllipse(B, CX - S * 0.25, CY - S * 0.25, S * 0.50, S * 0.50);
  finally
    B.Free;
    P.Free;
  end;
end;

procedure TModuloIcono.Paint;
var
  G: TGPGraphics;
  P: TGPPen;
  B: TGPSolidBrush;
  CX, CY, R: Single;
  ColTrazo, ColAro, ColFondo: Cardinal;
begin
  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);

    CX := Width / 2;
    CY := Height / 2;
    R := Min(Width, Height) / 2 - 2;

    // El COLOR es el estado, para leer la tarjeta sin buscar la casilla:
    // verde = contratado, terracota = no contratado.
    //
    // Terracota y NO rojo a proposito: el rojo significa error o alarma, y un
    // modulo que el cliente no ha comprado no es ninguna de las dos cosas. Una
    // pantalla con cuatro tarjetas rojas haria pensar que algo va mal cuando
    // simplemente es la licencia que se ha vendido.
    if FActivo then
    begin
      ColTrazo := MakeColor(255, 40, 110, 60);      // verde profundo
      ColAro   := MakeColor(255, 120, 180, 130);
      ColFondo := MakeColor(255, 232, 245, 233);
    end
    else
    begin
      ColTrazo := MakeColor(255, 180, 118, 58);     // terracota
      ColAro   := MakeColor(255, 216, 176, 146);
      ColFondo := MakeColor(255, 250, 240, 236);
    end;

    B := TGPSolidBrush.Create(ColFondo);
    P := TGPPen.Create(ColAro, 1.6);
    try
      G.FillEllipse(B, CX - R, CY - R, R * 2, R * 2);
      G.DrawEllipse(P, CX - R, CY - R, R * 2, R * 2);
    finally
      P.Free;
      B.Free;
    end;

    DibujarGlifo(G, CX, CY, R, ColTrazo);
  finally
    G.Free;
  end;
end;

{ TfrmModulosConfig }

class function TfrmModulosConfig.Execute: Boolean;
var
  F: TfrmModulosConfig;
begin
  Result := False;
  F := TfrmModulosConfig.Create(nil);
  try
    THelpViewer.InstallHelp(F, 'uModulosConfig', 'M'#243'dulos contratados');

    F.FModulos := ListarModulos;
    F.ConstruirTarjetas;
    F.ActualizarAviso(nil);

    if F.ShowModal <> mrOk then Exit;

    F.RecogerCambios;
    GuardarModulos(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa, F.FModulos);
    Result := True;
  finally
    // Las listas solo guardan referencias: los controles los libera el Owner
    // (el formulario), no estas listas.
    F.FChks.Free;
    F.FFechas.Free;
    F.FObs.Free;
    F.FIconos.Free;
    F.Free;
  end;
end;

procedure TfrmModulosConfig.ConstruirTarjetas;
var
  I, Y: Integer;
  Pnl: TPanel;
  L: TLabel;
  Chk: TcxCheckBox;
  Fecha: TcxDateEdit;
  Obs: TcxTextEdit;
  Ico: TModuloIcono;
begin
  FChks := TList<TcxCheckBox>.Create;
  FFechas := TList<TcxDateEdit>.Create;
  FObs := TList<TcxTextEdit>.Create;
  FIconos := TList<TModuloIcono>.Create;

  Y := SEP;
  for I := 0 to High(FModulos) do
  begin
    Pnl := TPanel.Create(Self);
    Pnl.Parent := sbModulos;
    Pnl.SetBounds(MARGEN, Y, sbModulos.ClientWidth - MARGEN * 2 - 20,
      ALTO_TARJETA);
    Pnl.Anchors := [akLeft, akTop, akRight];
    Pnl.BevelOuter := bvNone;
    Pnl.BorderStyle := bsSingle;
    Pnl.ParentBackground := False;
    // El color de fondo ES el estado: se ve de un vistazo que tiene contratado
    // el cliente sin leer una sola casilla.
    if FModulos[I].Activo then Pnl.Color := COL_ON else Pnl.Color := COL_OFF;

    // Icono del modulo: refuerza el estado (color) y hace la lista navegable
    // de un vistazo, sin leer los nombres uno a uno.
    Ico := TModuloIcono.Create(Self);
    Ico.Parent := Pnl;
    Ico.SetBounds(14, 24, 44, 44);
    Ico.Codigo := FModulos[I].Codigo;
    Ico.Activo := FModulos[I].Activo;
    FIconos.Add(Ico);

    // Casilla + nombre comercial.
    Chk := TcxCheckBox.Create(Self);
    Chk.Parent := Pnl;
    Chk.SetBounds(68, 10, 330, 21);
    Chk.Caption := FModulos[I].Nombre;
    Chk.Checked := FModulos[I].Activo;
    Chk.Transparent := True;
    Chk.Style.Font.Style := [fsBold];
    Chk.Style.Font.Size := 10;
    Chk.Tag := I;
    Chk.Properties.OnChange := ActualizarAviso;
    FChks.Add(Chk);

    // Que incluye.
    L := TLabel.Create(Self);
    L.Parent := Pnl;
    L.SetBounds(88, 33, Pnl.Width - 400, 32);
    L.Anchors := [akLeft, akTop, akRight];
    L.AutoSize := False;
    L.WordWrap := True;
    L.Font.Color := clGray;
    L.ParentFont := False;
    L.Caption := FModulos[I].Descripcion;

    // Aviso de si el cliente lo ve o no cuando esta apagado. Importa: es la
    // diferencia entre "no existe" y "existe y le invitamos a comprarlo".
    L := TLabel.Create(Self);
    L.Parent := Pnl;
    L.SetBounds(88, 67, Pnl.Width - 400, 15);
    L.Anchors := [akLeft, akTop, akRight];
    L.AutoSize := False;
    L.Font.Color := $00A0A0A0;
    L.Font.Size := 8;
    L.ParentFont := False;
    if FModulos[I].MostrarSiApagado then
      L.Caption := #$25CF' Si no est'#225' contratado, el cliente lo ve en gris ' +
        'con una invitaci'#243'n a solicitarlo.'
    else
      L.Caption := #$25CB' Si no est'#225' contratado, no aparece en los men'#250's.';

    // Caducidad.
    L := TLabel.Create(Self);
    L.Parent := Pnl;
    L.SetBounds(Pnl.Width - 300, 12, 80, 15);
    L.Anchors := [akTop, akRight];
    L.Caption := 'Caduca el';
    L.Font.Color := clGray;
    L.ParentFont := False;

    Fecha := TcxDateEdit.Create(Self);
    Fecha.Parent := Pnl;
    Fecha.SetBounds(Pnl.Width - 300, 30, 110, 21);
    Fecha.Anchors := [akTop, akRight];
    // Vacio = sin caducidad. Clear deja el editor en blanco; no hace falta
    // tocar Properties (ShowNullDate no existe en esta version del control).
    if FModulos[I].FechaCaducidad > 0 then
      Fecha.Date := FModulos[I].FechaCaducidad
    else
      Fecha.Clear;
    Fecha.Hint := 'Vac'#237'o = sin caducidad (licencia perpetua)';
    Fecha.ShowHint := True;
    FFechas.Add(Fecha);

    // Observaciones del comercial.
    L := TLabel.Create(Self);
    L.Parent := Pnl;
    L.SetBounds(Pnl.Width - 180, 12, 100, 15);
    L.Anchors := [akTop, akRight];
    L.Caption := 'Observaciones';
    L.Font.Color := clGray;
    L.ParentFont := False;

    Obs := TcxTextEdit.Create(Self);
    Obs.Parent := Pnl;
    Obs.SetBounds(Pnl.Width - 180, 30, 165, 21);
    Obs.Anchors := [akTop, akRight];
    Obs.Text := FModulos[I].Observaciones;
    Obs.Properties.MaxLength := 500;
    Obs.Hint := 'N'#186' de pedido, condiciones, con qui'#233'n se habl'#243'...';
    Obs.ShowHint := True;
    FObs.Add(Obs);

    Inc(Y, ALTO_TARJETA + SEP);
  end;
end;

procedure TfrmModulosConfig.ActualizarAviso(Sender: TObject);
var
  I, Activos: Integer;
  Chk: TcxCheckBox;
begin
  if FChks = nil then Exit;

  Activos := 0;
  for I := 0 to FChks.Count - 1 do
  begin
    Chk := FChks[I];
    if Chk.Checked then Inc(Activos);
    // Repintar la tarjeta al vuelo: el estado se ve mientras se decide, sin
    // tener que guardar para comprobar como queda.
    if Chk.Parent is TPanel then
      if Chk.Checked then
        TPanel(Chk.Parent).Color := COL_ON
      else
        TPanel(Chk.Parent).Color := COL_OFF;
    if (FIconos <> nil) and (I < FIconos.Count) then
      FIconos[I].Activo := Chk.Checked;
  end;

  // Resumen con semaforo: nadie contrata "0 de 7", y verlo en rojo evita
  // guardar una licencia vacia por descuido.
  lblAviso.Caption := Format(
    '%d de %d m'#243'dulos contratados'#$2003'  Los cambios se aplican al momento.',
    [Activos, FChks.Count]);
  // Mismo codigo de color que las tarjetas: verde si esta todo contratado,
  // terracota si no hay NADA (probablemente un descuido: nadie vende una
  // licencia sin modulos), neutro en cualquier reparto intermedio, que es lo
  // normal y no merece llamar la atencion.
  if Activos = 0 then
    lblAviso.Font.Color := $003A76B4      // terracota (BGR)
  else if Activos = FChks.Count then
    lblAviso.Font.Color := $003C6E28      // verde (BGR)
  else
    lblAviso.Font.Color := clGray;
end;

procedure TfrmModulosConfig.RecogerCambios;
var
  I: Integer;
begin
  for I := 0 to High(FModulos) do
  begin
    if I < FChks.Count then
      FModulos[I].Activo := FChks[I].Checked;
    if I < FFechas.Count then
    begin
      // Editor vacio = sin caducidad. Se comprueban Null Y Empty: un cxDateEdit
      // recien limpiado puede devolver cualquiera de los dos, y leer .Date
      // sobre un valor sin asignar lanza.
      if VarIsNull(FFechas[I].EditValue) or VarIsEmpty(FFechas[I].EditValue) then
        FModulos[I].FechaCaducidad := 0
      else if FFechas[I].Date <= 0 then
        FModulos[I].FechaCaducidad := 0
      else
        FModulos[I].FechaCaducidad := FFechas[I].Date;
    end;
    if I < FObs.Count then
      FModulos[I].Observaciones := FObs[I].Text;
  end;
end;

end.
