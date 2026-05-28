unit uModalOverlayAuto;

(*
  Hook global que aplica un overlay fosc semi-transparent darrere de qualsevol
  ShowModal del projecte sense haver de tocar els call sites.

  S'enganxa via TApplicationEvents (OnModalBegin / OnModalEnd) a la
  initialization de la unit. N'hi ha prou amb afegir-la al .dpr.

  Funciona tambe per MessageDlg / InputBox (qualsevol TCustomForm.ShowModal).
*)

interface

implementation

uses
  Winapi.Windows, System.Classes, System.SysUtils,
  Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.AppEvnts, System.Types;

const
  COverlayAlpha = 170;
  COverlayColor = $00101010;

type
  TOverlayForm = class(TForm)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

  TModalHook = class
  private
    FAppEvents: TApplicationEvents;
    FOverlays: TList;          // pila de TOverlayForm (un per nivell modal)
    procedure HandleModalBegin(Sender: TObject);
    procedure HandleModalEnd(Sender: TObject);
    function FindOwnerForm: TForm;
    function ComputeOverlayRect(AOwnerForm: TForm): TRect;
  public
    constructor Create;
    destructor Destroy; override;
  end;

procedure TOverlayForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle or WS_EX_NOACTIVATE;
end;

constructor TModalHook.Create;
begin
  inherited Create;
  FOverlays := TList.Create;
  FAppEvents := TApplicationEvents.Create(nil);
  FAppEvents.OnModalBegin := HandleModalBegin;
  FAppEvents.OnModalEnd := HandleModalEnd;
end;

destructor TModalHook.Destroy;
var
  I: Integer;
begin
  for I := FOverlays.Count - 1 downto 0 do
    TOverlayForm(FOverlays[I]).Free;
  FOverlays.Free;
  FAppEvents.Free;
  inherited;
end;

function TModalHook.FindOwnerForm: TForm;
var
  AF: TCustomForm;
begin
  AF := Screen.ActiveCustomForm;
  // ActiveCustomForm acaba sent el modal que s'esta obrint; busquem el pare
  // que esta al darrere. Si no es possible, caiem a MainForm.
  if (AF <> nil) and (AF is TForm) and (TForm(AF).FormStyle <> fsMDIChild) then
  begin
    // Si el form actiu es ja el modal (fsModal), volem un altre: el seu Owner
    // si es TForm, o el MainForm.
    if (AF.Owner <> nil) and (AF.Owner is TForm) then
      Result := TForm(AF.Owner)
    else
      Result := Application.MainForm;
  end
  else
    Result := Application.MainForm;
end;

function TModalHook.ComputeOverlayRect(AOwnerForm: TForm): TRect;
begin
  if (AOwnerForm = nil) or not AOwnerForm.HandleAllocated then
    Result := Screen.DesktopRect
  else
    GetWindowRect(AOwnerForm.Handle, Result);
end;

procedure TModalHook.HandleModalBegin(Sender: TObject);
var
  Overlay: TOverlayForm;
  Owner: TForm;
  R: TRect;
begin
  Owner := FindOwnerForm;
  if (Owner = nil) or not Owner.Visible then
  begin
    FOverlays.Add(nil);   // marcador, sense overlay per aquest nivell
    Exit;
  end;

  Overlay := TOverlayForm.CreateNew(nil);
  Overlay.BorderStyle := bsNone;
  Overlay.FormStyle := fsStayOnTop;
  Overlay.Position := poDesigned;
  Overlay.Color := COverlayColor;
  Overlay.AlphaBlend := True;
  Overlay.AlphaBlendValue := COverlayAlpha;
  Overlay.Enabled := False;

  R := ComputeOverlayRect(Owner);
  Overlay.SetBounds(R.Left, R.Top, R.Width, R.Height);
  Overlay.Show;
  FOverlays.Add(Overlay);
end;

procedure TModalHook.HandleModalEnd(Sender: TObject);
var
  Idx: Integer;
  Overlay: TOverlayForm;
begin
  Idx := FOverlays.Count - 1;
  if Idx < 0 then Exit;
  Overlay := TOverlayForm(FOverlays[Idx]);
  FOverlays.Delete(Idx);
  if Overlay <> nil then
    Overlay.Free;
end;

var
  GHook: TModalHook = nil;

initialization
  GHook := TModalHook.Create;

finalization
  FreeAndNil(GHook);

end.
