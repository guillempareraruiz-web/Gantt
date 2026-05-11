unit uAusenciaEdit;

{
  TfrmAusenciaEdit - Mini formulario modal para crear o editar una ausencia.

  Modos:
    - D'ia(s) completo(s): rangos por fecha (sin componente horario).
    - Tramo horario: una unica fecha + hora inicio + hora fin (mismo d'ia,
      no se admite cross-midnight; para nocturnos crear dos tramos).

  Validacion:
    - D'ia: FechaFin > FechaInicio.
    - Horas: HoraFin > HoraInicio.
  La validacion de solapamientos se hace en el formulario llamador.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, uOperariosTypes;

type
  TfrmAusenciaEdit = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlBody: TPanel;
    lblTipo: TLabel;
    cbTipo: TComboBox;
    lblFechaInicio: TLabel;
    dtpFechaInicio: TDateTimePicker;
    lblFechaFin: TLabel;
    dtpFechaFin: TDateTimePicker;
    lblDescripcion: TLabel;
    mmDescripcion: TMemo;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    shpTipoColor: TShape;
    lblModo: TLabel;
    rbDia: TRadioButton;
    rbHoras: TRadioButton;
    lblFechaUnica: TLabel;
    dtpFechaUnica: TDateTimePicker;
    lblHoraInicio: TLabel;
    dtpHoraInicio: TDateTimePicker;
    lblHoraFin: TLabel;
    dtpHoraFin: TDateTimePicker;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbTipoChange(Sender: TObject);
    procedure dtpFechaInicioChange(Sender: TObject);
    procedure dtpHoraInicioChange(Sender: TObject);
    procedure rbModoClick(Sender: TObject);
  private
    FAusencia: TAusencia;
    procedure LoadFromAusencia;
    procedure SaveToAusencia;
    procedure UpdateColorPreview;
    procedure UpdateModoUI;
  public
    class function Execute(var AAusencia: TAusencia;
      AOperarioNombre: string): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmAusenciaEdit.Execute(var AAusencia: TAusencia;
  AOperarioNombre: string): Boolean;
var
  F: TfrmAusenciaEdit;
begin
  F := TfrmAusenciaEdit.Create(nil);
  try
    F.FAusencia := AAusencia;
    F.LoadFromAusencia;
    if AAusencia.Id = 0 then
      F.lblTitle.Caption := 'Nueva ausencia - ' + AOperarioNombre
    else
      F.lblTitle.Caption := 'Editar ausencia - ' + AOperarioNombre;
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      F.SaveToAusencia;
      AAusencia := F.FAusencia;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmAusenciaEdit.FormCreate(Sender: TObject);
var
  T: TTipoAusencia;
begin
  Position := poScreenCenter;
  cbTipo.Items.Clear;
  for T := Low(TTipoAusencia) to High(TTipoAusencia) do
    cbTipo.Items.Add(TipoAusenciaToStr(T));
  cbTipo.ItemIndex := 0;
  dtpFechaInicio.Date := Trunc(Now);
  dtpFechaFin.Date := Trunc(Now) + 1;
  dtpFechaUnica.Date := Trunc(Now);
  dtpHoraInicio.Time := EncodeTime(8, 0, 0, 0);
  dtpHoraFin.Time := EncodeTime(12, 0, 0, 0);
  rbDia.Checked := True;
  UpdateColorPreview;
  UpdateModoUI;
end;

procedure TfrmAusenciaEdit.LoadFromAusencia;
begin
  cbTipo.ItemIndex := Ord(FAusencia.Tipo);

  if FAusencia.EsHoraria then
  begin
    rbHoras.Checked := True;
    if FAusencia.FechaInicio > 0 then
    begin
      dtpFechaUnica.Date := DateOf(FAusencia.FechaInicio);
      dtpHoraInicio.Time := TimeOf(FAusencia.FechaInicio);
      dtpHoraFin.Time := TimeOf(FAusencia.FechaFin);
    end
    else
    begin
      dtpFechaUnica.Date := Trunc(Now);
      dtpHoraInicio.Time := EncodeTime(8, 0, 0, 0);
      dtpHoraFin.Time := EncodeTime(12, 0, 0, 0);
    end;
  end
  else
  begin
    rbDia.Checked := True;
    if FAusencia.FechaInicio > 0 then
      dtpFechaInicio.Date := DateOf(FAusencia.FechaInicio)
    else
      dtpFechaInicio.Date := Trunc(Now);
    if FAusencia.FechaFin > 0 then
      dtpFechaFin.Date := DateOf(FAusencia.FechaFin)
    else
      dtpFechaFin.Date := Trunc(Now) + 1;
  end;

  mmDescripcion.Text := FAusencia.Descripcion;
  UpdateColorPreview;
  UpdateModoUI;
end;

procedure TfrmAusenciaEdit.SaveToAusencia;
var
  D: TDateTime;
begin
  FAusencia.Tipo := TTipoAusencia(cbTipo.ItemIndex);
  FAusencia.EsHoraria := rbHoras.Checked;
  if FAusencia.EsHoraria then
  begin
    D := DateOf(dtpFechaUnica.Date);
    FAusencia.FechaInicio := D + TimeOf(dtpHoraInicio.Time);
    FAusencia.FechaFin := D + TimeOf(dtpHoraFin.Time);
  end
  else
  begin
    FAusencia.FechaInicio := DateOf(dtpFechaInicio.Date);
    FAusencia.FechaFin := DateOf(dtpFechaFin.Date);
  end;
  FAusencia.Descripcion := Trim(mmDescripcion.Text);
end;

procedure TfrmAusenciaEdit.UpdateColorPreview;
var
  T: TTipoAusencia;
begin
  if (cbTipo.ItemIndex < 0) then Exit;
  T := TTipoAusencia(cbTipo.ItemIndex);
  shpTipoColor.Brush.Color := TipoAusenciaColor(T);
end;

procedure TfrmAusenciaEdit.UpdateModoUI;
var
  Horario: Boolean;
begin
  Horario := rbHoras.Checked;

  // Modo dia (rango fecha-fecha)
  lblFechaInicio.Visible := not Horario;
  dtpFechaInicio.Visible := not Horario;
  lblFechaFin.Visible := not Horario;
  dtpFechaFin.Visible := not Horario;

  // Modo horario (fecha unica + hora inicio/fin)
  lblFechaUnica.Visible := Horario;
  dtpFechaUnica.Visible := Horario;
  lblHoraInicio.Visible := Horario;
  dtpHoraInicio.Visible := Horario;
  lblHoraFin.Visible := Horario;
  dtpHoraFin.Visible := Horario;
end;

procedure TfrmAusenciaEdit.cbTipoChange(Sender: TObject);
begin
  UpdateColorPreview;
end;

procedure TfrmAusenciaEdit.rbModoClick(Sender: TObject);
begin
  UpdateModoUI;
end;

procedure TfrmAusenciaEdit.dtpFechaInicioChange(Sender: TObject);
begin
  if dtpFechaFin.Date <= dtpFechaInicio.Date then
    dtpFechaFin.Date := dtpFechaInicio.Date + 1;
end;

procedure TfrmAusenciaEdit.dtpHoraInicioChange(Sender: TObject);
begin
  if TimeOf(dtpHoraFin.Time) <= TimeOf(dtpHoraInicio.Time) then
    dtpHoraFin.Time := IncMinute(dtpHoraInicio.Time, 60);
end;

procedure TfrmAusenciaEdit.btnOKClick(Sender: TObject);
begin
  if rbHoras.Checked then
  begin
    if TimeOf(dtpHoraFin.Time) <= TimeOf(dtpHoraInicio.Time) then
    begin
      MessageDlg('La hora de fin debe ser posterior a la hora de inicio.',
        mtWarning, [mbOK], 0);
      ModalResult := mrNone;
      Exit;
    end;
  end
  else
  begin
    if Trunc(dtpFechaFin.Date) <= Trunc(dtpFechaInicio.Date) then
    begin
      MessageDlg('La fecha de fin debe ser posterior a la fecha de inicio.',
        mtWarning, [mbOK], 0);
      ModalResult := mrNone;
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

end.
