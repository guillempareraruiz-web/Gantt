unit uGanttDatesDialog;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar,
  dxSkinsCore, dxSkinsDefaultPainters;

type
  TfrmGanttDatesDialog = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    lblFechaInicio: TLabel;
    lblFechaFin: TLabel;
    dtFechaInicio: TcxDateEdit;
    dtFechaFin: TcxDateEdit;
    lblHelp: TLabel;
    procedure btnOKClick(Sender: TObject);
  public
    class function Execute(var AFechaInicio, AFechaFin: TDateTime): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmGanttDatesDialog.Execute(
  var AFechaInicio, AFechaFin: TDateTime): Boolean;
var
  F: TfrmGanttDatesDialog;
begin
  F := TfrmGanttDatesDialog.Create(Application);
  try
    F.dtFechaInicio.Date := AFechaInicio;
    F.dtFechaFin.Date := AFechaFin;
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      AFechaInicio := F.dtFechaInicio.Date;
      AFechaFin := F.dtFechaFin.Date;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmGanttDatesDialog.btnOKClick(Sender: TObject);
begin
  if dtFechaInicio.Date >= dtFechaFin.Date then
  begin
    ShowMessage('La fecha inicial debe ser anterior a la fecha final.');
    ModalResult := mrNone;
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
