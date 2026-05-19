unit uExcepcionRecurrenteDialog;

// Dialogo para crear excepciones recurrentes tipo:
//   "Cada primer lunes de mes, mantenimiento 14-16h"
// El usuario elige patron (ordinal + dia semana), tipo (festivo/pausa) y rango de meses,
// ve preview de las fechas y confirma.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.UITypes,
  System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  uCalendarsRepo;

type
  TfrmExcepcionRecurrente = class(TForm)
    pnlTop: TPanel;
    lblOrdinal: TLabel;
    cbOrdinal: TComboBox;
    lblDia: TLabel;
    cbDia: TComboBox;
    lblPatron: TLabel;
    lblAnio: TLabel;
    edAnio: TEdit;
    udAnio: TUpDown;
    rbFestivo: TRadioButton;
    rbPausa: TRadioButton;
    lblHoraIni: TLabel;
    dtHoraIni: TDateTimePicker;
    lblHoraFin: TLabel;
    dtHoraFin: TDateTimePicker;
    lblDescripcion: TLabel;
    edDescripcion: TEdit;
    lbPreview: TListBox;
    lblPreviewTitulo: TLabel;
    pnlBottom: TPanel;
    btnCrear: TButton;
    btnCancel: TButton;
    procedure FormShow(Sender: TObject);
    procedure cbOrdinalChange(Sender: TObject);
    procedure cbDiaChange(Sender: TObject);
    procedure udAnioClick(Sender: TObject; Button: TUDBtnType);
    procedure rbFestivoClick(Sender: TObject);
    procedure rbPausaClick(Sender: TObject);
    procedure btnCrearClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FRepo: TCalendarsRepo;
    FCodigoEmpresa: SmallInt;
    FCalendarId: Integer;
    FCalendarNombre: string;
    FFechas: TArray<TDate>;
    procedure RefreshHoras;
    procedure RecomputePreview;
    function ComputeNthDow(AYear, AMonth, AOrdinal, ADow: Integer): TDate;
  public
    class function Execute(ARepo: TCalendarsRepo; ACodigoEmpresa: SmallInt;
      ACalendarId: Integer; const ACalendarNombre: string;
      AAnioInicial: Word): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmExcepcionRecurrente.Execute(ARepo: TCalendarsRepo;
  ACodigoEmpresa: SmallInt; ACalendarId: Integer;
  const ACalendarNombre: string; AAnioInicial: Word): Boolean;
var
  F: TfrmExcepcionRecurrente;
begin
  F := TfrmExcepcionRecurrente.Create(Application);
  try
    F.FRepo := ARepo;
    F.FCodigoEmpresa := ACodigoEmpresa;
    F.FCalendarId := ACalendarId;
    F.FCalendarNombre := ACalendarNombre;
    F.udAnio.Position := AAnioInicial;
    F.edAnio.Text := IntToStr(AAnioInicial);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmExcepcionRecurrente.FormShow(Sender: TObject);
begin
  Caption := 'Excepci'#243'n recurrente - ' + FCalendarNombre;

  cbOrdinal.Items.Clear;
  cbOrdinal.Items.Add('Primer');
  cbOrdinal.Items.Add('Segundo');
  cbOrdinal.Items.Add('Tercer');
  cbOrdinal.Items.Add('Cuarto');
  cbOrdinal.Items.Add(#218'ltimo');  // Último
  cbOrdinal.ItemIndex := 0;

  cbDia.Items.Clear;
  cbDia.Items.Add('Lunes');
  cbDia.Items.Add('Martes');
  cbDia.Items.Add('Mi'#233'rcoles');
  cbDia.Items.Add('Jueves');
  cbDia.Items.Add('Viernes');
  cbDia.Items.Add('S'#225'bado');
  cbDia.Items.Add('Domingo');
  cbDia.ItemIndex := 0;

  rbFestivo.Checked := True;
  dtHoraIni.Time := EncodeTime(13, 0, 0, 0);
  dtHoraFin.Time := EncodeTime(15, 0, 0, 0);
  RefreshHoras;
  RecomputePreview;
end;

procedure TfrmExcepcionRecurrente.RefreshHoras;
begin
  dtHoraIni.Enabled := rbPausa.Checked;
  dtHoraFin.Enabled := rbPausa.Checked;
  lblHoraIni.Enabled := rbPausa.Checked;
  lblHoraFin.Enabled := rbPausa.Checked;
end;

// Calcula la fecha de la N-esima ocurrencia (1..4) o ultima (5) del dia ADow (1=Lu..7=Do)
// dentro del mes AMonth de AYear. Retorna 0 si no existe.
function TfrmExcepcionRecurrente.ComputeNthDow(
  AYear, AMonth, AOrdinal, ADow: Integer): TDate;
var
  D, DaysInMo: Integer;
  Found: Integer;
  LastMatch: TDate;
begin
  Result := 0;
  DaysInMo := DaysInMonth(EncodeDate(AYear, AMonth, 1));
  LastMatch := 0;
  Found := 0;

  for D := 1 to DaysInMo do
    if DayOfTheWeek(EncodeDate(AYear, AMonth, D)) = ADow then
    begin
      Inc(Found);
      LastMatch := EncodeDate(AYear, AMonth, D);
      if (AOrdinal >= 1) and (AOrdinal <= 4) and (Found = AOrdinal) then
      begin
        Result := LastMatch;
        Exit;
      end;
    end;

  if AOrdinal = 5 then
    Result := LastMatch;
end;

procedure TfrmExcepcionRecurrente.RecomputePreview;
var
  Anio, M: Integer;
  Ord, Dow: Integer;
  Fecha: TDate;
  TipoTxt: string;
begin
  lbPreview.Items.Clear;
  SetLength(FFechas, 0);

  if (cbOrdinal.ItemIndex < 0) or (cbDia.ItemIndex < 0) then Exit;

  Anio := udAnio.Position;
  Ord := cbOrdinal.ItemIndex + 1;             // 1..5
  Dow := cbDia.ItemIndex + 1;                 // 1=Lu..7=Do

  if rbFestivo.Checked then
    TipoTxt := 'Festivo'
  else
    TipoTxt := Format('Pausa %s-%s',
      [FormatDateTime('hh:nn', dtHoraIni.Time),
       FormatDateTime('hh:nn', dtHoraFin.Time)]);

  for M := 1 to 12 do
  begin
    Fecha := ComputeNthDow(Anio, M, Ord, Dow);
    if Fecha = 0 then Continue;

    SetLength(FFechas, Length(FFechas) + 1);
    FFechas[High(FFechas)] := Fecha;

    lbPreview.Items.Add(
      FormatDateTime('dd/mm/yyyy ddd', Fecha) + '  -  ' + TipoTxt);
  end;

  lblPreviewTitulo.Caption :=
    Format('Vista previa (%d fechas en %d):', [Length(FFechas), Anio]);
end;

procedure TfrmExcepcionRecurrente.cbOrdinalChange(Sender: TObject);
begin
  RecomputePreview;
end;

procedure TfrmExcepcionRecurrente.cbDiaChange(Sender: TObject);
begin
  RecomputePreview;
end;

procedure TfrmExcepcionRecurrente.udAnioClick(Sender: TObject;
  Button: TUDBtnType);
begin
  RecomputePreview;
end;

procedure TfrmExcepcionRecurrente.rbFestivoClick(Sender: TObject);
begin
  RefreshHoras;
  RecomputePreview;
end;

procedure TfrmExcepcionRecurrente.rbPausaClick(Sender: TObject);
begin
  RefreshHoras;
  RecomputePreview;
end;

procedure TfrmExcepcionRecurrente.btnCrearClick(Sender: TObject);
var
  I: Integer;
  EsLab: Boolean;
  HIni, HFin: TTime;
  Desc: string;
  Insertadas, Saltadas: Integer;
begin
  if Length(FFechas) = 0 then
  begin
    ShowMessage('No hay fechas para crear.');
    Exit;
  end;

  if rbPausa.Checked and (dtHoraFin.Time <= dtHoraIni.Time) then
  begin
    ShowMessage('La hora de fin debe ser posterior a la de inicio.');
    Exit;
  end;

  EsLab := rbPausa.Checked;
  HIni := dtHoraIni.Time;
  HFin := dtHoraFin.Time;
  Desc := Trim(edDescripcion.Text);

  Insertadas := 0;
  Saltadas := 0;
  for I := 0 to High(FFechas) do
  begin
    try
      FRepo.AddException(FCodigoEmpresa, FCalendarId, FFechas[I],
        EsLab, HIni, HFin, Desc);
      Inc(Insertadas);
    except
      Inc(Saltadas);
    end;
  end;

  ShowMessage(Format('Excepciones recurrentes creadas.'#13#10 +
    'Insertadas: %d'#13#10 +
    'Saltadas (ya exist'#237'an): %d', [Insertadas, Saltadas]));

  ModalResult := mrOk;
end;

procedure TfrmExcepcionRecurrente.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
