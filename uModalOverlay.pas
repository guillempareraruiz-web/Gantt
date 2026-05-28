unit uModalOverlay;

(*
  DEPRECATED: l'overlay ara s'aplica automaticament a tot ShowModal del
  projecte via uModalOverlayAuto (hook a Application.OnModalBegin/End).
  Aquesta unit es manté com a thin wrapper per compatibilitat amb els call
  sites existents; internament només crida ShowModal.
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

function ShowModalWithOverlay(AModal: TForm; AOwnerForm: TForm;
  AAlpha: Byte; AColor: TColor): Integer;
begin
  if AModal = nil then Exit(mrCancel);
  Result := AModal.ShowModal;
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
