unit uBacklogSchedParams;

{
  Dialogo modal de parametros de auto-planificacion del Backlog.
  Recuerda los ultimos valores por usuario via FS_PL_Cfg_UserPrefs.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  uBacklogScheduler;

type
  TfrmBacklogSchedParams = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnCalcular: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    lblModo: TLabel;
    lblOrden: TLabel;
    lblFechaBase: TLabel;
    lblFechaHint: TLabel;
    rbForward: TRadioButton;
    rbBackward: TRadioButton;
    rbOrdenFecha: TRadioButton;
    rbOrdenPrio: TRadioButton;
    dtFechaBase: TDateTimePicker;
    procedure FormCreate(Sender: TObject);
  private
    FParams: TSchedParams;
    procedure ApplyToUI;
    procedure ReadFromUI;
    procedure LoadLastParams;
    procedure SaveLastParams;
  public
    property Params: TSchedParams read FParams write FParams;
    class function Execute(var AParams: TSchedParams): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils,
  uUserPrefs;

const
  MOD_NAME = 'BACKLOG_SCHED';

class function TfrmBacklogSchedParams.Execute(var AParams: TSchedParams): Boolean;
var
  F: TfrmBacklogSchedParams;
begin
  F := TfrmBacklogSchedParams.Create(Application);
  try
    F.FParams := AParams;
    F.ApplyToUI;
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      F.ReadFromUI;
      F.SaveLastParams;
      AParams := F.FParams;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmBacklogSchedParams.FormCreate(Sender: TObject);
begin
  LoadLastParams;
  ApplyToUI;
end;

procedure TfrmBacklogSchedParams.ApplyToUI;
begin
  rbForward.Checked  := FParams.Mode = smForward;
  rbBackward.Checked := FParams.Mode = smBackward;
  rbOrdenFecha.Checked := FParams.Order = soFechaCompromiso;
  rbOrdenPrio.Checked  := FParams.Order = soPrioridad;
  if FParams.FechaBase = 0 then
    dtFechaBase.Date := Date
  else
    dtFechaBase.Date := FParams.FechaBase;
end;

procedure TfrmBacklogSchedParams.ReadFromUI;
begin
  if rbBackward.Checked then FParams.Mode := smBackward
  else FParams.Mode := smForward;
  if rbOrdenPrio.Checked then FParams.Order := soPrioridad
  else FParams.Order := soFechaCompromiso;
  FParams.FechaBase := dtFechaBase.Date;
end;

procedure TfrmBacklogSchedParams.LoadLastParams;
var
  ModeVal, OrderVal: Integer;
  FechaStr: string;
  D: TDateTime;
begin
  ModeVal  := uUserPrefs.GetPrefInt(MOD_NAME, 'Mode',  Ord(smBackward));
  OrderVal := uUserPrefs.GetPrefInt(MOD_NAME, 'Order', Ord(soFechaCompromiso));
  FechaStr := uUserPrefs.GetPref(MOD_NAME, 'FechaBase', '');

  case ModeVal of
    0: FParams.Mode := smForward;
    1: FParams.Mode := smBackward;
  else
    FParams.Mode := smBackward;
  end;
  case OrderVal of
    0: FParams.Order := soFechaCompromiso;
    1: FParams.Order := soPrioridad;
  else
    FParams.Order := soFechaCompromiso;
  end;
  if TryStrToDate(FechaStr, D) then
    FParams.FechaBase := D
  else
    FParams.FechaBase := Date;
end;

procedure TfrmBacklogSchedParams.SaveLastParams;
begin
  uUserPrefs.SetPrefInt(MOD_NAME, 'Mode',  Ord(FParams.Mode));
  uUserPrefs.SetPrefInt(MOD_NAME, 'Order', Ord(FParams.Order));
  uUserPrefs.SetPref(MOD_NAME, 'FechaBase',
    FormatDateTime('yyyy-mm-dd', FParams.FechaBase));
end;

end.
