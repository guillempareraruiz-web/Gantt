unit uBusyDialog;

// ============================================================================
// Form modal-less reutilizable para dar feedback de "Cargando..." al usuario
// durante operaciones bloqueantes en el thread principal (queries SQL,
// importaciones, etc.).
//
// Uso tipico:
//
//   var Busy := TfrmBusyDialog.Show(Self, 'Cargando datos...');
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
// El form NO usa thread: simplemente se pinta antes de la operacion lenta y
// se libera al final. Suficiente cuando solo se quiere feedback visual.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics;

type
  TfrmBusyDialog = class(TForm)
    pnlBorder: TPanel;
    lblMessage: TLabel;
  private
    FOldCursor: TCursor;
  public
    class function Display(AOwner: TForm; const AMessage: string): TfrmBusyDialog;
    procedure UpdateMessage(const AMessage: string);
    destructor Destroy; override;
  end;

procedure ShowBusy(AOwner: TForm; const AMessage: string; AProc: TProc);

implementation

{$R *.dfm}

class function TfrmBusyDialog.Display(AOwner: TForm;
  const AMessage: string): TfrmBusyDialog;
begin
  Result := TfrmBusyDialog.Create(AOwner);
  Result.lblMessage.Caption := AMessage;
  Result.FOldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  // Show no-modal: el form aparece pero no bloquea al thread principal.
  Result.Show;
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

end.
