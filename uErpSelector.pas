unit uErpSelector;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  uErpTypes;

type
  TfrmErpSelector = class(TForm)
    pnlIzq: TPanel;
    lblTituloLista: TLabel;
    lstErps: TListBox;
    pnlDer: TPanel;
    pnlDetalle: TPanel;
    imgLogo: TImage;
    lblNombre: TLabel;
    lblEstado: TLabel;
    lblDescripcion: TLabel;
    btnPreferencias: TButton;
    btnProbarConexion: TButton;
    lblResultado: TLabel;
    pnlBotones: TPanel;
    btnGuardar: TButton;
    btnCancelar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure lstErpsClick(Sender: TObject);
    procedure lstErpsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure btnPreferenciasClick(Sender: TObject);
    procedure btnProbarConexionClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
  private
    FSeleccionado: TErpSistema;
    procedure CargarLista;
    procedure SeleccionarPorCodigo(const ACodigo: string);
    procedure RefrescarDetalle;
    procedure DibujarLogoPlaceholder(ACanvas: TCanvas; const ARect: TRect;
      const AIniciales: string; ADisponible: Boolean);
  public
    class function Execute: Boolean;
  end;

implementation

{$R *.dfm}

uses
  uAppConfig, uErpPrefsSage200;

class function TfrmErpSelector.Execute: Boolean;
var
  Frm: TfrmErpSelector;
begin
  Frm := TfrmErpSelector.Create(nil);
  try
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

procedure TfrmErpSelector.FormCreate(Sender: TObject);
begin
  CargarLista;
  SeleccionarPorCodigo(LoadErpActivo);
end;

procedure TfrmErpSelector.CargarLista;
var
  E: TErpSistema;
begin
  lstErps.Items.BeginUpdate;
  try
    lstErps.Items.Clear;
    for E := Low(TErpSistema) to High(TErpSistema) do
      lstErps.Items.AddObject(ERP_SISTEMAS[E].Nombre, TObject(Ord(E)));
  finally
    lstErps.Items.EndUpdate;
  end;
end;

procedure TfrmErpSelector.SeleccionarPorCodigo(const ACodigo: string);
var
  E: TErpSistema;
  Idx: Integer;
begin
  Idx := 0;
  for E := Low(TErpSistema) to High(TErpSistema) do
    if SameText(ERP_SISTEMAS[E].Codigo, ACodigo) then
    begin
      Idx := Ord(E);
      Break;
    end;
  lstErps.ItemIndex := Idx;
  FSeleccionado := TErpSistema(Idx);
  RefrescarDetalle;
end;

procedure TfrmErpSelector.lstErpsClick(Sender: TObject);
begin
  if lstErps.ItemIndex < 0 then Exit;
  FSeleccionado := TErpSistema(lstErps.ItemIndex);
  RefrescarDetalle;
end;

procedure TfrmErpSelector.RefrescarDetalle;
var
  Info: TErpSistemaInfo;
  Bmp: TBitmap;
begin
  Info := ERP_SISTEMAS[FSeleccionado];
  lblNombre.Caption      := Info.Nombre;
  lblDescripcion.Caption := Info.Descripcion;

  if Info.Disponible then
  begin
    lblEstado.Caption := 'Disponible';
    lblEstado.Font.Color := clGreen;
  end
  else
  begin
    lblEstado.Caption := 'Pr'#243'ximamente';
    lblEstado.Font.Color := clGray;
  end;

  btnPreferencias.Enabled    := Info.Disponible;
  btnProbarConexion.Enabled  := Info.Disponible;
  btnGuardar.Enabled         := Info.Disponible;
  lblResultado.Caption       := '';

  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(imgLogo.Width, imgLogo.Height);
    DibujarLogoPlaceholder(Bmp.Canvas,
      Rect(0, 0, Bmp.Width, Bmp.Height),
      Info.Iniciales, Info.Disponible);
    imgLogo.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TfrmErpSelector.DibujarLogoPlaceholder(ACanvas: TCanvas;
  const ARect: TRect; const AIniciales: string; ADisponible: Boolean);
var
  TxtRect: TRect;
begin
  if ADisponible then
    ACanvas.Brush.Color := $00B97A2A
  else
    ACanvas.Brush.Color := clSilver;
  ACanvas.FillRect(ARect);

  ACanvas.Pen.Color := clGray;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Rectangle(ARect);

  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 32;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := clWhite;
  TxtRect := ARect;
  DrawText(ACanvas.Handle, PChar(UpperCase(AIniciales)), -1, TxtRect,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

procedure TfrmErpSelector.lstErpsDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Lb: TListBox;
  Info: TErpSistemaInfo;
  TxtRect: TRect;
  EstadoTxt: string;
begin
  Lb := Control as TListBox;
  if (Index < 0) or (Index >= Lb.Items.Count) then Exit;

  Info := ERP_SISTEMAS[TErpSistema(Index)];

  if odSelected in State then
    Lb.Canvas.Brush.Color := clHighlight
  else
    Lb.Canvas.Brush.Color := clWindow;
  Lb.Canvas.FillRect(Rect);

  Lb.Canvas.Font.Name := 'Segoe UI';
  Lb.Canvas.Font.Size := 11;
  Lb.Canvas.Font.Style := [fsBold];
  if odSelected in State then
    Lb.Canvas.Font.Color := clHighlightText
  else if Info.Disponible then
    Lb.Canvas.Font.Color := clWindowText
  else
    Lb.Canvas.Font.Color := clGrayText;

  TxtRect := Rect;
  TxtRect.Left := Rect.Left + 12;
  TxtRect.Top := Rect.Top + 8;
  TxtRect.Bottom := TxtRect.Top + 22;
  DrawText(Lb.Canvas.Handle, PChar(Info.Nombre), -1, TxtRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

  Lb.Canvas.Font.Size := 9;
  Lb.Canvas.Font.Style := [];
  if Info.Disponible then
    EstadoTxt := 'Disponible'
  else
    EstadoTxt := 'Pr'#243'ximamente';

  if not (odSelected in State) then
  begin
    if Info.Disponible then
      Lb.Canvas.Font.Color := clGreen
    else
      Lb.Canvas.Font.Color := clGray;
  end;

  TxtRect.Top := Rect.Top + 30;
  TxtRect.Bottom := Rect.Bottom - 4;
  DrawText(Lb.Canvas.Handle, PChar(EstadoTxt), -1, TxtRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);
end;

procedure TfrmErpSelector.btnPreferenciasClick(Sender: TObject);
begin
  case FSeleccionado of
    esSage200:
      TfrmErpPrefsSage200.Execute;
  else
    ShowMessage('Preferencias para ' + ERP_SISTEMAS[FSeleccionado].Nombre +
      ' a'#250'n no implementadas.');
  end;
end;

procedure TfrmErpSelector.btnProbarConexionClick(Sender: TObject);
begin
  if not ERP_SISTEMAS[FSeleccionado].Disponible then Exit;

  lblResultado.Font.Color := clBlue;
  lblResultado.Caption := 'Probando conexi'#243'n con ' +
    ERP_SISTEMAS[FSeleccionado].Nombre + '...';
  Application.ProcessMessages;

  // TODO: invocar test real cuando IErpReader esté implementado.
  lblResultado.Font.Color := clOlive;
  lblResultado.Caption := 'Test de conexi'#243'n a'#250'n no implementado para ' +
    ERP_SISTEMAS[FSeleccionado].Nombre + '.';
end;

procedure TfrmErpSelector.btnGuardarClick(Sender: TObject);
begin
  if not ERP_SISTEMAS[FSeleccionado].Disponible then
  begin
    ShowMessage('El ERP seleccionado a'#250'n no est'#225' disponible.');
    ModalResult := mrNone;
    Exit;
  end;
  SaveErpActivo(ERP_SISTEMAS[FSeleccionado].Codigo);
end;

end.
