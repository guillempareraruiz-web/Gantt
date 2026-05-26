unit uModalOverlay;

(*
  Helper per mostrar un form modal amb un overlay fosc semi-transparent
  pintat per sobre del form pare. L'overlay desapareix automaticament
  quan el modal es tanca.

  Us:
    ShowModalWithOverlay(F)        -> retorna ModalResult
    ShowModalWithOverlay(F, AOwner) -> overlay sobre AOwner (per defecte: AOwner del form)
*)

interface

uses
  System.Classes, Vcl.Forms, Vcl.Controls, Vcl.Graphics;

const
  DefaultOverlayAlpha = 170;   // 0..255 (mes alt = mes fosc)
  DefaultOverlayColor = $00101010;

function ShowModalWithOverlay(AModal: TForm): Integer; overload;
function ShowModalWithOverlay(AModal: TForm; AOwnerForm: TForm): Integer; overload;
function ShowModalWithOverlay(AModal: TForm; AOwnerForm: TForm;
  AAlpha: Byte; AColor: TColor): Integer; overload;

implementation

uses
  Winapi.Windows, System.Types;

type
  TOverlayForm = class(TForm)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

procedure TOverlayForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // WS_EX_NOACTIVATE: que no robi el focus al modal.
  Params.ExStyle := Params.ExStyle or WS_EX_NOACTIVATE;
end;

var
  GOverlayDepth: Integer = 0;   // nivells d'overlay actius (nested modals)

function FindBestOwnerForm(AModal: TForm): TForm;
begin
  if (AModal.Owner <> nil) and (AModal.Owner is TForm) then
    Result := TForm(AModal.Owner)
  else if Screen.ActiveForm <> nil then
    Result := Screen.ActiveForm
  else
    Result := Application.MainForm;
end;

// Calcula el rect que ha de cobrir l'overlay: el rect exacte de la finestra
// pare (Main), incloent titlebar i marcs.
function ComputeOverlayRect(AOwnerForm: TForm): TRect;
begin
  if (AOwnerForm = nil) or not AOwnerForm.HandleAllocated then
    Result := Screen.DesktopRect
  else
    GetWindowRect(AOwnerForm.Handle, Result);
end;

function ShowModalWithOverlay(AModal: TForm; AOwnerForm: TForm;
  AAlpha: Byte; AColor: TColor): Integer;
var
  Overlay: TOverlayForm;
  TargetRect: TRect;
  NeedOverlay: Boolean;
begin
  if AModal = nil then
  begin
    Result := mrCancel;
    Exit;
  end;

  if AOwnerForm = nil then
    AOwnerForm := FindBestOwnerForm(AModal);

  // Si ja hi ha un overlay actiu (modal anidat), no en posem un altre.
  NeedOverlay := (GOverlayDepth = 0) and Assigned(AOwnerForm)
    and AOwnerForm.Visible;

  if not NeedOverlay then
  begin
    Result := AModal.ShowModal;
    Exit;
  end;

  Overlay := TOverlayForm.CreateNew(AOwnerForm);
  try
    Overlay.BorderStyle := bsNone;
    Overlay.FormStyle := fsStayOnTop;
    Overlay.Position := poDesigned;
    Overlay.Color := AColor;
    Overlay.AlphaBlend := True;
    Overlay.AlphaBlendValue := AAlpha;
    Overlay.Enabled := False;   // que no rebi clicks (van al modal)

    TargetRect := ComputeOverlayRect(AOwnerForm);
    Overlay.SetBounds(TargetRect.Left, TargetRect.Top,
      TargetRect.Width, TargetRect.Height);
    Overlay.Show;

    Inc(GOverlayDepth);
    try
      Result := AModal.ShowModal;
    finally
      Dec(GOverlayDepth);
      Overlay.Hide;
    end;
  finally
    Overlay.Free;
  end;
end;

function ShowModalWithOverlay(AModal: TForm; AOwnerForm: TForm): Integer;
begin
  Result := ShowModalWithOverlay(AModal, AOwnerForm,
    DefaultOverlayAlpha, DefaultOverlayColor);
end;

function ShowModalWithOverlay(AModal: TForm): Integer;
begin
  Result := ShowModalWithOverlay(AModal, nil,
    DefaultOverlayAlpha, DefaultOverlayColor);
end;

end.
