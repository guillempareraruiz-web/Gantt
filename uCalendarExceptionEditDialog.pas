unit uCalendarExceptionEditDialog;

// ============================================================================
// Dialog modal para anadir/editar una excepcion (TfrmCalendarExceptionsEdit usa
// este dialog inline cuando el usuario pulsa Anadir o Editar).
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  uCalendarsRepo;

type
  TfrmCalendarExceptionEditDialog = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblFecha: TLabel;
    dtFecha: TDateTimePicker;
    rbFestivo: TRadioButton;
    rbLaborable: TRadioButton;
    lblHoraIni: TLabel;
    dtHoraIni: TDateTimePicker;
    lblHoraFin: TLabel;
    dtHoraFin: TDateTimePicker;
    lblDescripcion: TLabel;
    edDescripcion: TEdit;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormShow(Sender: TObject);
    procedure rbFestivoClick(Sender: TObject);
    procedure rbLaborableClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FRepo: TCalendarsRepo;
    FCodigoEmpresa: SmallInt;
    FCalendarId: Integer;
    FExceptionId: Integer;
    FEsNuevo: Boolean;
    procedure RefreshHorasEnabled;
    procedure LoadExistingException;
  public
    class function Execute(ARepo: TCalendarsRepo; ACodigoEmpresa: SmallInt;
      ACalendarId: Integer; AExceptionId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmCalendarExceptionEditDialog.Execute(ARepo: TCalendarsRepo;
  ACodigoEmpresa: SmallInt; ACalendarId: Integer; AExceptionId: Integer): Boolean;
var
  F: TfrmCalendarExceptionEditDialog;
begin
  F := TfrmCalendarExceptionEditDialog.Create(Application);
  try
    F.FRepo := ARepo;
    F.FCodigoEmpresa := ACodigoEmpresa;
    F.FCalendarId := ACalendarId;
    F.FExceptionId := AExceptionId;
    F.FEsNuevo := (AExceptionId <= 0);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmCalendarExceptionEditDialog.FormShow(Sender: TObject);
begin
  if FEsNuevo then
  begin
    Caption := 'Nueva excepci'#243'n';
    dtFecha.Date := Date;
    rbFestivo.Checked := True;
    dtHoraIni.Time := EncodeTime(8, 0, 0, 0);
    dtHoraFin.Time := EncodeTime(13, 0, 0, 0);
    edDescripcion.Text := '';
  end
  else
  begin
    Caption := 'Editar excepci'#243'n';
    LoadExistingException;
  end;
  RefreshHorasEnabled;
end;

procedure TfrmCalendarExceptionEditDialog.LoadExistingException;
var
  Items: TArray<TCalendarExceptionRec>;
  i: Integer;
begin
  Items := FRepo.LoadExceptions(FCodigoEmpresa, FCalendarId);
  for i := 0 to High(Items) do
    if Items[i].ExceptionId = FExceptionId then
    begin
      dtFecha.Date := Items[i].Fecha;
      if Items[i].EsLaborable then
      begin
        rbLaborable.Checked := True;
        dtHoraIni.Time := Items[i].HoraInicio;
        dtHoraFin.Time := Items[i].HoraFin;
      end
      else
        rbFestivo.Checked := True;
      edDescripcion.Text := Items[i].Descripcion;
      Exit;
    end;
end;

procedure TfrmCalendarExceptionEditDialog.RefreshHorasEnabled;
begin
  dtHoraIni.Enabled := rbLaborable.Checked;
  dtHoraFin.Enabled := rbLaborable.Checked;
  lblHoraIni.Enabled := rbLaborable.Checked;
  lblHoraFin.Enabled := rbLaborable.Checked;
end;

procedure TfrmCalendarExceptionEditDialog.rbFestivoClick(Sender: TObject);
begin
  RefreshHorasEnabled;
end;

procedure TfrmCalendarExceptionEditDialog.rbLaborableClick(Sender: TObject);
begin
  RefreshHorasEnabled;
end;

procedure TfrmCalendarExceptionEditDialog.btnOKClick(Sender: TObject);
var
  EsLab: Boolean;
  HIni, HFin: TTime;
  Desc: string;
begin
  EsLab := rbLaborable.Checked;
  HIni := dtHoraIni.Time;
  HFin := dtHoraFin.Time;
  Desc := Trim(edDescripcion.Text);

  if EsLab and (HFin <= HIni) then
  begin
    ShowMessage('La hora de fin debe ser posterior a la de inicio.');
    Exit;
  end;

  try
    if FEsNuevo then
      FExceptionId := FRepo.AddException(FCodigoEmpresa, FCalendarId,
        dtFecha.Date, EsLab, HIni, HFin, Desc)
    else
      FRepo.UpdateException(FCodigoEmpresa, FExceptionId,
        dtFecha.Date, EsLab, HIni, HFin, Desc);
    ModalResult := mrOk;
  except
    on E: Exception do
      ShowMessage('Error al guardar: ' + E.Message);
  end;
end;

procedure TfrmCalendarExceptionEditDialog.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
