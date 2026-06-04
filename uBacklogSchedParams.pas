unit uBacklogSchedParams;

{
  Dialogo modal de parametros de auto-planificacion del Backlog.
  Recuerda los ultimos valores por usuario via FS_PL_Cfg_UserPrefs.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Samples.Spin,
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
    lblPlacement: TLabel;
    cbPlacement: TComboBox;
    lblHuecoMin: TLabel;
    seHuecoMin: TSpinEdit;
    lblPctNodo: TLabel;
    sePctNodo: TSpinEdit;
    lblDistMin: TLabel;
    seDistMin: TSpinEdit;
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
  uUserPrefs, uGanttConfig;

const
  MOD_NAME = 'BACKLOG_SCHED';

class function TfrmBacklogSchedParams.Execute(var AParams: TSchedParams): Boolean;
var
  F: TfrmBacklogSchedParams;
begin
  F := TfrmBacklogSchedParams.Create(Application);
  try
    // Cargar siempre los defaults desde la config del Gantt (BD). NO usamos
    // AParams de entrada (suele venir vacio del caller); los valores guardados
    // mandan. La FechaBase de la ultima tanda se recupera dentro de LoadLastParams.
    F.LoadLastParams;
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
var
  P: TPlacementPolicy;
begin
  cbPlacement.Items.Clear;
  for P := Low(TPlacementPolicy) to High(TPlacementPolicy) do
    cbPlacement.Items.Add(PlacementToStr(P));
  // LoadLastParams + ApplyToUI los invoca Execute tras crear el form, para que
  // los defaults de la config (BD) no sean sobreescritos por el AParams vacio.
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
  cbPlacement.ItemIndex := Ord(FParams.Placement);
  seHuecoMin.Value := FParams.HuecoMinimoMin;
  sePctNodo.Value := FParams.PorcentajeMinNodo;
  seDistMin.Value := FParams.DistanciaMinNodos;
end;

procedure TfrmBacklogSchedParams.ReadFromUI;
begin
  if rbBackward.Checked then FParams.Mode := smBackward
  else FParams.Mode := smForward;
  if rbOrdenPrio.Checked then FParams.Order := soPrioridad
  else FParams.Order := soFechaCompromiso;
  FParams.FechaBase := dtFechaBase.Date;
  if cbPlacement.ItemIndex >= 0 then
    FParams.Placement := TPlacementPolicy(cbPlacement.ItemIndex)
  else
    FParams.Placement := ppHueco;
  FParams.HuecoMinimoMin := seHuecoMin.Value;
  FParams.PorcentajeMinNodo := sePctNodo.Value;
  FParams.DistanciaMinNodos := seDistMin.Value;
end;

procedure TfrmBacklogSchedParams.LoadLastParams;
var
  Cfg: TGanttConfig;
  FechaStr: string;
  D: TDateTime;
begin
  // Los defaults (modo, orden, colocacion, umbrales) vienen de la configuracion
  // central del Gantt (fuente unica de verdad). Aqui solo recordamos la
  // FechaBase de la ultima tanda, que es puntual de cada planificacion.
  Cfg := LoadGanttConfig;
  ApplyConfigToSchedParams(Cfg, FParams);
  FParams.Mode := Cfg.Mode;
  FParams.Order := Cfg.Order;

  FechaStr := uUserPrefs.GetPref(MOD_NAME, 'FechaBase', '');
  if TryStrToDate(FechaStr, D) then
    FParams.FechaBase := D
  else
    FParams.FechaBase := Date;
end;

procedure TfrmBacklogSchedParams.SaveLastParams;
begin
  // Solo persistimos la FechaBase de la tanda. Modo/orden/colocacion/umbrales
  // se gestionan en Preferencias del Gantt (no se sobreescriben desde aqui).
  uUserPrefs.SetPref(MOD_NAME, 'FechaBase',
    FormatDateTime('yyyy-mm-dd', FParams.FechaBase));
end;

end.
