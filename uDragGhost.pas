unit uDragGhost;

(*
  Ghost visual durant drag & drop.
  Captura un bitmap del control origen i el pinta com una "ombra" semi-
  transparent que segueix el cursor. Independent del sistema de drag VCL.

  Us tipic:
    DragGhost.Show(MiControl);   // a OnStartDrag / al inici del drag
    DragGhost.Hide;              // a OnEndDrag / al final
  El form es mou sol via Application.OnIdle, no cal fer res mes.

  Singleton accessit via DragGhost.
*)

interface

uses
  Winapi.Windows, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.Graphics,
  Vcl.ExtCtrls;

type
  TDragGhostForm = class(TForm)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

  TDragGhost = class
  private
    FForm: TDragGhostForm;
    FImg: TImage;
    FBmp: TBitmap;
    FOldIdle: TIdleEvent;
    FOffsetX, FOffsetY: Integer;
    FActive: Boolean;
    procedure OnIdle(Sender: TObject; var Done: Boolean);
    procedure EnsureForm;
  public
    destructor Destroy; override;
    procedure Show(ASource: TControl); overload;
    procedure Show(ASource: TControl; AOffsetX, AOffsetY: Integer); overload;
    procedure Hide;
    property Active: Boolean read FActive;
  end;

function DragGhost: TDragGhost;

implementation

var
  GGhost: TDragGhost = nil;

function DragGhost: TDragGhost;
begin
  if GGhost = nil then
    GGhost := TDragGhost.Create;
  Result := GGhost;
end;

{ TDragGhostForm }

procedure TDragGhostForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // No activable -> no roba el focus al control origen
  Params.ExStyle := Params.ExStyle or WS_EX_NOACTIVATE or WS_EX_TOOLWINDOW
    or WS_EX_TRANSPARENT;
end;

{ TDragGhost }

procedure TDragGhost.EnsureForm;
begin
  if FForm <> nil then Exit;
  FForm := TDragGhostForm.CreateNew(nil);
  FForm.BorderStyle := bsNone;
  FForm.FormStyle := fsStayOnTop;
  FForm.Position := poDesigned;
  FForm.AlphaBlend := True;
  FForm.AlphaBlendValue := 210;
  FForm.Color := clWhite;
  FForm.Enabled := False;

  FImg := TImage.Create(FForm);
  FImg.Parent := FForm;
  FImg.Align := alClient;
  FImg.Stretch := False;

  FBmp := TBitmap.Create;
end;

destructor TDragGhost.Destroy;
begin
  Hide;
  FBmp.Free;
  FForm.Free;
  inherited;
end;

procedure TDragGhost.Show(ASource: TControl);
begin
  Show(ASource, 12, 12);
end;

procedure TDragGhost.Show(ASource: TControl; AOffsetX, AOffsetY: Integer);
var
  W, H: Integer;
  WinSrc: TWinControl;
begin
  if ASource = nil then Exit;
  EnsureForm;

  W := ASource.Width;
  H := ASource.Height;
  if (W <= 0) or (H <= 0) then Exit;

  FBmp.SetSize(W, H);
  FBmp.Canvas.Brush.Color := clWhite;
  FBmp.Canvas.FillRect(Rect(0, 0, W, H));

  // PaintTo nomes funciona sobre TWinControl. Per controls graphics
  // (TLabel, etc.) fem servir el parent i copiem la regio.
  if ASource is TWinControl then
    TWinControl(ASource).PaintTo(FBmp.Canvas.Handle, 0, 0)
  else
  begin
    WinSrc := ASource.Parent;
    if WinSrc <> nil then
    begin
      WinSrc.PaintTo(FBmp.Canvas.Handle, -ASource.Left, -ASource.Top);
    end;
  end;

  FImg.Picture.Assign(FBmp);

  FOffsetX := AOffsetX;
  FOffsetY := AOffsetY;
  FForm.ClientWidth := W;
  FForm.ClientHeight := H;

  // Posicionar sota el cursor
  var Pt: TPoint;
  GetCursorPos(Pt);
  FForm.Left := Pt.X + FOffsetX;
  FForm.Top := Pt.Y + FOffsetY;

  // Mostrar sense activar
  SetWindowPos(FForm.Handle, HWND_TOPMOST, FForm.Left, FForm.Top,
    FForm.Width, FForm.Height,
    SWP_NOACTIVATE or SWP_SHOWWINDOW);

  FOldIdle := Application.OnIdle;
  Application.OnIdle := OnIdle;
  FActive := True;
end;

procedure TDragGhost.Hide;
begin
  if not FActive then Exit;
  Application.OnIdle := FOldIdle;
  FOldIdle := nil;
  if FForm <> nil then
    ShowWindow(FForm.Handle, SW_HIDE);
  FActive := False;
end;

procedure TDragGhost.OnIdle(Sender: TObject; var Done: Boolean);
var
  Pt: TPoint;
begin
  if FActive and (FForm <> nil) then
  begin
    GetCursorPos(Pt);
    SetWindowPos(FForm.Handle, 0, Pt.X + FOffsetX, Pt.Y + FOffsetY, 0, 0,
      SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOZORDER);
  end;
  if Assigned(FOldIdle) then
    FOldIdle(Sender, Done);
  Done := False;  // continua repetint
end;

initialization
finalization
  GGhost.Free;
end.
