unit uGestionTurnos;

{
  TfrmGestionTurnos - Editor de turnos de trabajo.

  Permite definir hasta 3 turnos con franja horaria, nombre y color.
  Incluye barra visual de 24h para validar solapamientos y huecos.
  Los turnos son globales de empresa (no por centro).
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Math, System.DateUtils, System.Generics.Collections,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.Win.ADODB, Data.DB,
  uGanttTypes;

const
  MAX_TURNOS = 3;
  NUM_TURNO_PROFILES = 4;

type
  TTurnoSlot = record
    Nombre: string;
    HI, MI: Word;  // hora inicio
    HF, MF: Word;  // hora fin
    Color: TColor;
  end;

  TTurnoProfile = record
    ProfileName: string;
    Slots: array[0..MAX_TURNOS - 1] of TTurnoSlot;
  end;

const
  TURNO_PROFILES: array[0..NUM_TURNO_PROFILES - 1] of TTurnoProfile = (
    ( ProfileName: 'Clasico (06-14-22)';
      Slots: (
        (Nombre: 'Mañana';    HI: 6;  MI: 0;  HF: 14; MF: 0;  Color: $0058B0FF),
        (Nombre: 'Tarde';     HI: 14; MI: 0;  HF: 22; MF: 0;  Color: $00FFA858),
        (Nombre: 'Noche';     HI: 22; MI: 0;  HF: 6;  MF: 0;  Color: $00886644) )),
    ( ProfileName: 'Tempranero (05-13-21)';
      Slots: (
        (Nombre: 'Turno A';   HI: 5;  MI: 0;  HF: 13; MF: 0;  Color: $0040C080),
        (Nombre: 'Turno B';   HI: 13; MI: 0;  HF: 21; MF: 0;  Color: $00C08040),
        (Nombre: 'Turno C';   HI: 21; MI: 0;  HF: 5;  MF: 0;  Color: $00604080) )),
    ( ProfileName: 'Media hora (06:30-14:30-22:30)';
      Slots: (
        (Nombre: 'Dia';       HI: 6;  MI: 30; HF: 14; MF: 30; Color: $000080FF),
        (Nombre: 'Tarde';     HI: 14; MI: 30; HF: 22; MF: 30; Color: $00FF8040),
        (Nombre: 'Nocturno';  HI: 22; MI: 30; HF: 6;  MF: 30; Color: $00505080) )),
    ( ProfileName: 'Estandar (07-15-23)';
      Slots: (
        (Nombre: '1er Turno'; HI: 7;  MI: 0;  HF: 15; MF: 0;  Color: $004CB050),
        (Nombre: '2do Turno'; HI: 15; MI: 0;  HF: 23; MF: 0;  Color: $00B0504C),
        (Nombre: '3er Turno'; HI: 23; MI: 0;  HF: 7;  MF: 0;  Color: $00504CB0) ))
  );

// Convierte un perfil de turnos a un array de TTurno
function ProfileToTurnos(const AProfileIdx: Integer): TArray<TTurno>;

type
  { --------------------------------------------------------- }
  {  TTimelineBar - barra visual 24h con turnos               }
  { --------------------------------------------------------- }
  TTimelineBar = class(TCustomControl)
  private const
    BAR_TOP = 24;
    BAR_H   = 36;
    PAD_L   = 40;
    PAD_R   = 16;
  private
    FTurnos: TArray<TTurno>;
    function HourToX(const H: Double): Integer;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetTurnos(const ATurnos: TArray<TTurno>);
  end;

  { --------------------------------------------------------- }
  {  TTurnoRowPanel - fila editable para un turno              }
  { --------------------------------------------------------- }
  TTurnoRowPanel = class(TPanel)
  private
    FTurno: TTurno;
    FEdtNombre: TEdit;
    FDtpInicio: TDateTimePicker;
    FDtpFin: TDateTimePicker;
    FPnlColor: TPanel;
    FChkActivo: TCheckBox;
    FBtnEliminar: TButton;
    FOnChanged: TNotifyEvent;
    FOnDelete: TNotifyEvent;
    procedure OnFieldChange(Sender: TObject);
    procedure OnColorClick(Sender: TObject);
    procedure OnDeleteClick(Sender: TObject);
    procedure ReadFromControls;
  public
    constructor CreateRow(AOwner: TComponent; AParent: TWinControl;
      const ATurno: TTurno; AOnChanged, AOnDelete: TNotifyEvent);
    function GetTurno: TTurno;
  end;

  { --------------------------------------------------------- }
  {  TfrmGestionTurnos - formulario principal                  }
  { --------------------------------------------------------- }
  TfrmGestionTurnos = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    pnlTimeline: TPanel;
    pnlList: TPanel;
    pnlFooter: TPanel;
    shpFooterLine: TShape;
    btnAnadir: TButton;
    btnAceptar: TButton;
    btnCancelar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnAnadirClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FTimeline: TTimelineBar;
    FRows: TObjectList<TTurnoRowPanel>;
    FScrollBox: TScrollBox;
    FNextId: Integer;
    FInitialTurnos: TArray<TTurno>;
    FLoaded: Boolean;

    // Combo de perfil
    FLblProfile: TLabel;
    FCmbProfile: TComboBox;

    procedure LoadInitialTurnos;
    procedure LoadFromDB;
    procedure SaveToDB(const ATurnos: TArray<TTurno>);
    procedure LoadProfile(const AProfileIdx: Integer);
    procedure OnProfileChange(Sender: TObject);
    procedure RebuildRowFromTurno(const ATurno: TTurno);
    procedure RebuildRows;
    procedure UpdateTimeline;
    procedure UpdateAddButton;
    function CollectTurnos: TArray<TTurno>;
    function ValidateTurnos(out AMsg: string): Boolean;
    procedure OnRowChanged(Sender: TObject);
    procedure OnRowDelete(Sender: TObject);
  public
    class procedure Execute;
  end;

implementation

uses
  uDMPlanner;

{$R *.dfm}

{ ========================================================= }
{                   ProfileToTurnos                         }
{ ========================================================= }

function ProfileToTurnos(const AProfileIdx: Integer): TArray<TTurno>;
var
  I: Integer;
  P: TTurnoProfile;
begin
  if (AProfileIdx < 0) or (AProfileIdx >= NUM_TURNO_PROFILES) then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  P := TURNO_PROFILES[AProfileIdx];
  SetLength(Result, MAX_TURNOS);
  for I := 0 to MAX_TURNOS - 1 do
  begin
    Result[I].Id := I + 1;
    Result[I].Nombre := P.Slots[I].Nombre;
    Result[I].HoraInicio := EncodeTime(P.Slots[I].HI, P.Slots[I].MI, 0, 0);
    Result[I].HoraFin := EncodeTime(P.Slots[I].HF, P.Slots[I].MF, 0, 0);
    Result[I].Color := P.Slots[I].Color;
    Result[I].Activo := True;
    Result[I].Order := I;
  end;
end;

{ ========================================================= }
{                     TTimelineBar                          }
{ ========================================================= }

constructor TTimelineBar.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
end;

procedure TTimelineBar.SetTurnos(const ATurnos: TArray<TTurno>);
begin
  FTurnos := ATurnos;
  Invalidate;
end;

function TTimelineBar.HourToX(const H: Double): Integer;
begin
  Result := PAD_L + Round((Width - PAD_L - PAD_R) * H / 24.0);
end;

procedure TTimelineBar.Paint;
var
  I: Integer;
  X1, X2, Y1, Y2: Integer;
  H, HI, HF: Double;
  S: string;
  TW: Integer;
begin
  inherited;
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ClientRect);

  Y1 := BAR_TOP;
  Y2 := BAR_TOP + BAR_H;

  // Fondo barra (gris claro = sin turno)
  Canvas.Brush.Color := $00F0F0F0;
  Canvas.Pen.Style := psClear;
  Canvas.RoundRect(PAD_L, Y1, Width - PAD_R, Y2, 6, 6);

  // Dibujar turnos
  for I := 0 to High(FTurnos) do
  begin
    if not FTurnos[I].Activo then Continue;

    HI := HourOf(FTurnos[I].HoraInicio) + MinuteOf(FTurnos[I].HoraInicio) / 60.0;
    HF := HourOf(FTurnos[I].HoraFin) + MinuteOf(FTurnos[I].HoraFin) / 60.0;

    Canvas.Brush.Color := FTurnos[I].Color;

    if HF > HI then
    begin
      // Turno normal (no cruza medianoche)
      X1 := HourToX(HI);
      X2 := HourToX(HF);
      Canvas.RoundRect(X1, Y1 + 2, X2, Y2 - 2, 4, 4);

      // Nombre centrado
      Canvas.Font.Name := 'Segoe UI';
      Canvas.Font.Size := 9;
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := clWhite;
      Canvas.Brush.Style := bsClear;
      TW := Canvas.TextWidth(FTurnos[I].Nombre);
      if (X2 - X1) > TW + 8 then
        Canvas.TextOut((X1 + X2 - TW) div 2, Y1 + 8, FTurnos[I].Nombre);
      Canvas.Brush.Style := bsSolid;
    end
    else if HF < HI then
    begin
      // Turno nocturno (cruza medianoche): dos bloques
      // Bloque 1: HI -> 24
      X1 := HourToX(HI);
      X2 := HourToX(24.0);
      Canvas.RoundRect(X1, Y1 + 2, X2, Y2 - 2, 4, 4);

      // Bloque 2: 0 -> HF
      X1 := HourToX(0);
      X2 := HourToX(HF);
      Canvas.RoundRect(X1, Y1 + 2, X2, Y2 - 2, 4, 4);

      // Nombre en el bloque mas grande
      Canvas.Font.Name := 'Segoe UI';
      Canvas.Font.Size := 9;
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := clWhite;
      Canvas.Brush.Style := bsClear;
      TW := Canvas.TextWidth(FTurnos[I].Nombre);
      X1 := HourToX(HI);
      X2 := HourToX(24.0);
      if (X2 - X1) > TW + 8 then
        Canvas.TextOut((X1 + X2 - TW) div 2, Y1 + 8, FTurnos[I].Nombre);
      Canvas.Brush.Style := bsSolid;
    end;
  end;

  // Marcas de hora
  Canvas.Pen.Style := psSolid;
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 7;
  Canvas.Font.Style := [];
  Canvas.Font.Color := $00888888;
  Canvas.Brush.Style := bsClear;

  for I := 0 to 24 do
  begin
    X1 := HourToX(I);
    // Tick
    Canvas.Pen.Color := $00CCCCCC;
    Canvas.MoveTo(X1, Y2);
    Canvas.LineTo(X1, Y2 + 4);

    // Etiqueta cada 2h o en 0/6/12/18/24
    if (I mod 2 = 0) then
    begin
      S := Format('%d:00', [I mod 24]);
      TW := Canvas.TextWidth(S);
      Canvas.TextOut(X1 - TW div 2, Y2 + 5, S);
    end;
  end;

  Canvas.Brush.Style := bsSolid;
end;

{ ========================================================= }
{                    TTurnoRowPanel                          }
{ ========================================================= }

constructor TTurnoRowPanel.CreateRow(AOwner: TComponent; AParent: TWinControl;
  const ATurno: TTurno; AOnChanged, AOnDelete: TNotifyEvent);
var
  Lbl: TLabel;
  X: Integer;
begin
  inherited Create(AOwner);
  // Asignar Parent ANTES de crear hijos (TDateTimePicker necesita handle)
  Parent := AParent;
  FTurno := ATurno;
  FOnChanged := AOnChanged;
  FOnDelete := AOnDelete;

  Height := 50;
  BevelOuter := bvNone;
  Color := clWhite;
  ParentBackground := False;

  X := 12;

  // Color swatch
  FPnlColor := TPanel.Create(Self);
  FPnlColor.Parent := Self;
  FPnlColor.SetBounds(X, 12, 28, 28);
  FPnlColor.BevelOuter := bvNone;
  FPnlColor.Color := ATurno.Color;
  FPnlColor.Cursor := crHandPoint;
  FPnlColor.ParentBackground := False;
  FPnlColor.OnClick := OnColorClick;
  X := X + 40;

  // Nombre
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.SetBounds(X, 2, 60, 15);
  Lbl.Caption := 'Nombre';
  Lbl.Font.Size := 8;
  Lbl.Font.Color := clGray;

  FEdtNombre := TEdit.Create(Self);
  FEdtNombre.Parent := Self;
  FEdtNombre.SetBounds(X, 18, 120, 24);
  FEdtNombre.Text := ATurno.Nombre;
  FEdtNombre.Font.Name := 'Segoe UI';
  FEdtNombre.Font.Size := 10;
  FEdtNombre.OnChange := OnFieldChange;
  X := X + 132;

  // Hora inicio
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.SetBounds(X, 2, 60, 15);
  Lbl.Caption := 'Inicio';
  Lbl.Font.Size := 8;
  Lbl.Font.Color := clGray;

  FDtpInicio := TDateTimePicker.Create(Self);
  FDtpInicio.Parent := Self;
  FDtpInicio.SetBounds(X, 18, 90, 24);
  FDtpInicio.Kind := dtkTime;
  FDtpInicio.Format := 'HH:mm';
  FDtpInicio.Time := ATurno.HoraInicio;
  FDtpInicio.Font.Name := 'Segoe UI';
  FDtpInicio.Font.Size := 10;
  FDtpInicio.OnChange := OnFieldChange;
  X := X + 100;

  // Hora fin
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.SetBounds(X, 2, 60, 15);
  Lbl.Caption := 'Fin';
  Lbl.Font.Size := 8;
  Lbl.Font.Color := clGray;

  FDtpFin := TDateTimePicker.Create(Self);
  FDtpFin.Parent := Self;
  FDtpFin.SetBounds(X, 18, 90, 24);
  FDtpFin.Kind := dtkTime;
  FDtpFin.Format := 'HH:mm';
  FDtpFin.Time := ATurno.HoraFin;
  FDtpFin.Font.Name := 'Segoe UI';
  FDtpFin.Font.Size := 10;
  FDtpFin.OnChange := OnFieldChange;
  X := X + 100;

  // Activo
  FChkActivo := TCheckBox.Create(Self);
  FChkActivo.Parent := Self;
  FChkActivo.SetBounds(X, 20, 60, 20);
  FChkActivo.Caption := 'Activo';
  FChkActivo.Checked := ATurno.Activo;
  FChkActivo.Font.Name := 'Segoe UI';
  FChkActivo.Font.Size := 9;
  FChkActivo.OnClick := OnFieldChange;
  X := X + 72;

  // Eliminar
  FBtnEliminar := TButton.Create(Self);
  FBtnEliminar.Parent := Self;
  FBtnEliminar.SetBounds(X, 16, 70, 26);
  FBtnEliminar.Caption := 'Eliminar';
  FBtnEliminar.Font.Name := 'Segoe UI';
  FBtnEliminar.Font.Size := 9;
  FBtnEliminar.OnClick := OnDeleteClick;
end;

procedure TTurnoRowPanel.ReadFromControls;
begin
  FTurno.Nombre := FEdtNombre.Text;
  FTurno.HoraInicio := Frac(FDtpInicio.Time);
  FTurno.HoraFin := Frac(FDtpFin.Time);
  FTurno.Color := FPnlColor.Color;
  FTurno.Activo := FChkActivo.Checked;
end;

function TTurnoRowPanel.GetTurno: TTurno;
begin
  ReadFromControls;
  Result := FTurno;
end;

procedure TTurnoRowPanel.OnFieldChange(Sender: TObject);
begin
  ReadFromControls;
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TTurnoRowPanel.OnColorClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(Self);
  try
    Dlg.Color := FPnlColor.Color;
    if Dlg.Execute then
    begin
      FPnlColor.Color := Dlg.Color;
      OnFieldChange(Sender);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTurnoRowPanel.OnDeleteClick(Sender: TObject);
begin
  if Assigned(FOnDelete) then
    FOnDelete(Self);
end;

{ ========================================================= }
{                   TfrmGestionTurnos                       }
{ ========================================================= }

procedure TfrmGestionTurnos.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FRows := TObjectList<TTurnoRowPanel>.Create(False);

  // Combo de perfil predefinido
  FLblProfile := TLabel.Create(Self);
  FLblProfile.Parent := pnlTimeline;
  FLblProfile.SetBounds(16, 6, 120, 18);
  FLblProfile.Caption := 'Perfil predefinido:';
  FLblProfile.Font.Name := 'Segoe UI';
  FLblProfile.Font.Size := 9;
  FLblProfile.Font.Style := [fsBold];
  FLblProfile.Font.Color := clGray;

  FCmbProfile := TComboBox.Create(Self);
  FCmbProfile.Parent := pnlTimeline;
  FCmbProfile.SetBounds(140, 3, 250, 24);
  FCmbProfile.Style := csDropDownList;
  FCmbProfile.Font.Name := 'Segoe UI';
  FCmbProfile.Font.Size := 9;
  FCmbProfile.Items.Add('-- Seleccionar perfil --');
  for I := 0 to NUM_TURNO_PROFILES - 1 do
    FCmbProfile.Items.Add(TURNO_PROFILES[I].ProfileName);
  FCmbProfile.ItemIndex := 0;
  FCmbProfile.OnChange := OnProfileChange;

  FTimeline := TTimelineBar.Create(Self);
  FTimeline.Parent := pnlTimeline;
  FTimeline.Align := alBottom;
  FTimeline.Height := 50;

  FScrollBox := TScrollBox.Create(Self);
  FScrollBox.Parent := pnlList;
  FScrollBox.Align := alClient;
  FScrollBox.BorderStyle := bsNone;
  FScrollBox.Color := clWhite;
  FScrollBox.VertScrollBar.Tracking := True;

  FNextId := 1;
end;

procedure TfrmGestionTurnos.FormDestroy(Sender: TObject);
begin
  FRows.Free;
end;

procedure TfrmGestionTurnos.FormShow(Sender: TObject);
begin
  if not FLoaded then
    LoadInitialTurnos;
end;

procedure TfrmGestionTurnos.LoadInitialTurnos;
var
  I: Integer;
begin
  if FLoaded then Exit;
  FLoaded := True;

  LoadFromDB;

  for I := 0 to High(FInitialTurnos) do
  begin
    if FInitialTurnos[I].Id >= FNextId then
      FNextId := FInitialTurnos[I].Id + 1;
    RebuildRowFromTurno(FInitialTurnos[I]);
  end;
  UpdateTimeline;
  UpdateAddButton;
end;

procedure TfrmGestionTurnos.LoadFromDB;
var
  Q: TADOQuery;
  I: Integer;
  T: TTurno;
begin
  SetLength(FInitialTurnos, 0);
  if not uDMPlanner.DMPlanner.IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := uDMPlanner.DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ShiftId, Nombre, ' +
      '  CAST(HoraInicio AS DATETIME) AS HoraIni, ' +
      '  CAST(HoraFin AS DATETIME) AS HoraFin, ' +
      '  ISNULL(Color, 0) AS Color, Activo, Orden ' +
      'FROM FS_PL_Shift ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY Orden, ShiftId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := uDMPlanner.DMPlanner.CodigoEmpresa;
    Q.Open;
    SetLength(FInitialTurnos, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      T.Id := Q.FieldByName('ShiftId').AsInteger;
      T.Nombre := Q.FieldByName('Nombre').AsString;
      T.HoraInicio := Frac(Q.FieldByName('HoraIni').AsDateTime);
      T.HoraFin := Frac(Q.FieldByName('HoraFin').AsDateTime);
      T.Color := TColor(Q.FieldByName('Color').AsInteger);
      T.Activo := Q.FieldByName('Activo').AsBoolean;
      T.Order := Q.FieldByName('Orden').AsInteger;
      FInitialTurnos[I] := T;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmGestionTurnos.SaveToDB(const ATurnos: TArray<TTurno>);
var
  Cmd: TADOCommand;
  I: Integer;
  CE: string;

  procedure Exec(const ASQL: string);
  begin
    Cmd.CommandText := ASQL;
    Cmd.Execute;
  end;

  function QStr(const S: string): string;
  begin
    Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
  end;

  function TimeStr(const T: TDateTime): string;
  begin
    Result := '''' + FormatDateTime('hh:nn:ss', T) + '''';
  end;

begin
  if not uDMPlanner.DMPlanner.IsConnected then Exit;

  CE := IntToStr(uDMPlanner.DMPlanner.CodigoEmpresa);
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := uDMPlanner.DMPlanner.ADOConnection;
    uDMPlanner.DMPlanner.ADOConnection.BeginTrans;
    try
      Exec('DELETE FROM FS_PL_Shift WHERE CodigoEmpresa = ' + CE);
      for I := 0 to High(ATurnos) do
      begin
        Exec('INSERT INTO FS_PL_Shift (CodigoEmpresa, Nombre, HoraInicio, HoraFin, Color, Activo, Orden) VALUES (' +
          CE + ', ' +
          QStr(ATurnos[I].Nombre) + ', ' +
          TimeStr(ATurnos[I].HoraInicio) + ', ' +
          TimeStr(ATurnos[I].HoraFin) + ', ' +
          IntToStr(Integer(ATurnos[I].Color)) + ', ' +
          IntToStr(Ord(ATurnos[I].Activo)) + ', ' +
          IntToStr(ATurnos[I].Order) + ')');
      end;
      uDMPlanner.DMPlanner.ADOConnection.CommitTrans;
    except
      uDMPlanner.DMPlanner.ADOConnection.RollbackTrans;
      raise;
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmGestionTurnos.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmGestionTurnos.btnAnadirClick(Sender: TObject);
var
  T: TTurno;
  Idx: Integer;
  S: TTurnoSlot;
begin
  if FRows.Count >= MAX_TURNOS then
  begin
    MessageDlg('Se permite un maximo de 3 turnos.', mtWarning, [mbOK], 0);
    Exit;
  end;

  Idx := FRows.Count;
  // Usar slot del perfil clasico (indice 0) como defaults
  S := TURNO_PROFILES[0].Slots[Idx];

  FillChar(T, SizeOf(T), 0);
  T.Id := FNextId;
  Inc(FNextId);
  T.Nombre := S.Nombre;
  T.HoraInicio := EncodeTime(S.HI, S.MI, 0, 0);
  T.HoraFin := EncodeTime(S.HF, S.MF, 0, 0);
  T.Color := S.Color;
  T.Activo := True;
  T.Order := Idx;

  RebuildRowFromTurno(T);
  UpdateTimeline;
  UpdateAddButton;
end;

procedure TfrmGestionTurnos.btnAceptarClick(Sender: TObject);
var
  Msg: string;
  Turnos: TArray<TTurno>;
begin
  if not ValidateTurnos(Msg) then
  begin
    MessageDlg(Msg, mtWarning, [mbOK], 0);
    Exit;
  end;
  Turnos := CollectTurnos;
  try
    SaveToDB(Turnos);
  except
    on E: Exception do
    begin
      MessageDlg('Error guardando turnos: ' + E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

procedure TfrmGestionTurnos.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmGestionTurnos.RebuildRowFromTurno(const ATurno: TTurno);
var
  Row: TTurnoRowPanel;
begin
  Row := TTurnoRowPanel.CreateRow(FScrollBox, FScrollBox, ATurno, OnRowChanged, OnRowDelete);
  Row.Align := alTop;
  Row.Top := MaxInt; // forzar al final
  FRows.Add(Row);
end;

procedure TfrmGestionTurnos.RebuildRows;
var
  Turnos: TArray<TTurno>;
  I: Integer;
begin
  // Recoger turnos actuales antes de limpiar
  Turnos := CollectTurnos;

  // Limpiar
  FRows.Clear;
  while FScrollBox.ControlCount > 0 do
    FScrollBox.Controls[0].Free;

  // Recrear
  for I := 0 to High(Turnos) do
    RebuildRowFromTurno(Turnos[I]);

  UpdateTimeline;
  UpdateAddButton;
end;

procedure TfrmGestionTurnos.UpdateTimeline;
begin
  FTimeline.SetTurnos(CollectTurnos);
end;

procedure TfrmGestionTurnos.UpdateAddButton;
begin
  btnAnadir.Enabled := FRows.Count < MAX_TURNOS;
  if FRows.Count >= MAX_TURNOS then
    btnAnadir.Caption := 'Maximo alcanzado'
  else
    btnAnadir.Caption := Format('Añadir turno (%d/%d)', [FRows.Count, MAX_TURNOS]);
end;

function TfrmGestionTurnos.CollectTurnos: TArray<TTurno>;
var
  I: Integer;
begin
  SetLength(Result, FRows.Count);
  for I := 0 to FRows.Count - 1 do
  begin
    Result[I] := FRows[I].GetTurno;
    Result[I].Order := I;
  end;
end;

function TfrmGestionTurnos.ValidateTurnos(out AMsg: string): Boolean;

  function TimeToMin(const T: TDateTime): Integer;
  begin
    Result := HourOf(T) * 60 + MinuteOf(T);
  end;

  function RangesOverlap(const A1, A2, B1, B2: Integer): Boolean;
  begin
    // Ambos rangos en minutos [0..1440)
    // A va de A1 a A2, B de B1 a B2
    // Hay solapamiento si comparten algun minuto
    Result := False;
    if (A1 = A2) or (B1 = B2) then Exit; // rango vacio
    if (A1 < A2) and (B1 < B2) then
      // Ambos normales
      Result := (A1 < B2) and (B1 < A2)
    else if (A1 > A2) and (B1 < B2) then
      // A cruza medianoche, B normal
      Result := (B1 < A2) or (B2 > A1)
    else if (A1 < A2) and (B1 > B2) then
      // A normal, B cruza medianoche
      Result := (A1 < B2) or (A2 > B1)
    else
      // Ambos cruzan medianoche -> siempre solapan
      Result := True;
  end;

var
  Turnos: TArray<TTurno>;
  I, J: Integer;
  MI1, MI2, MJ1, MJ2: Integer;
begin
  Result := True;
  AMsg := '';
  Turnos := CollectTurnos;

  for I := 0 to High(Turnos) do
  begin
    if not Turnos[I].Activo then Continue;
    if Trim(Turnos[I].Nombre) = '' then
    begin
      AMsg := Format('El turno %d no tiene nombre.', [I + 1]);
      Exit(False);
    end;

    MI1 := TimeToMin(Turnos[I].HoraInicio);
    MI2 := TimeToMin(Turnos[I].HoraFin);

    if MI1 = MI2 then
    begin
      AMsg := Format('El turno "%s" tiene hora inicio igual a hora fin.',
        [Turnos[I].Nombre]);
      Exit(False);
    end;

    // Comprobar solapamiento con los demas
    for J := I + 1 to High(Turnos) do
    begin
      if not Turnos[J].Activo then Continue;
      MJ1 := TimeToMin(Turnos[J].HoraInicio);
      MJ2 := TimeToMin(Turnos[J].HoraFin);

      if RangesOverlap(MI1, MI2, MJ1, MJ2) then
      begin
        AMsg := Format('Los turnos "%s" y "%s" se solapan.',
          [Turnos[I].Nombre, Turnos[J].Nombre]);
        Exit(False);
      end;
    end;
  end;
end;

procedure TfrmGestionTurnos.OnRowChanged(Sender: TObject);
begin
  UpdateTimeline;
end;

procedure TfrmGestionTurnos.OnRowDelete(Sender: TObject);
var
  Row: TTurnoRowPanel;
begin
  Row := Sender as TTurnoRowPanel;
  FRows.Remove(Row);
  Row.Free;
  UpdateTimeline;
  UpdateAddButton;
end;

{ --- Perfil de turnos --- }

procedure TfrmGestionTurnos.OnProfileChange(Sender: TObject);
begin
  if FCmbProfile.ItemIndex <= 0 then Exit;
  LoadProfile(FCmbProfile.ItemIndex - 1); // -1 porque indice 0 es "Seleccionar"
end;

procedure TfrmGestionTurnos.LoadProfile(const AProfileIdx: Integer);
var
  Turnos: TArray<TTurno>;
  I: Integer;
begin
  Turnos := ProfileToTurnos(AProfileIdx);

  // Limpiar filas actuales
  FRows.Clear;
  while FScrollBox.ControlCount > 0 do
    FScrollBox.Controls[0].Free;

  // Crear filas con los turnos del perfil
  FNextId := 1;
  for I := 0 to High(Turnos) do
  begin
    Turnos[I].Id := FNextId;
    Inc(FNextId);
    RebuildRowFromTurno(Turnos[I]);
  end;

  UpdateTimeline;
  UpdateAddButton;
end;

{ --- Punto de entrada --- }

class procedure TfrmGestionTurnos.Execute;
var
  F: TfrmGestionTurnos;
begin
  F := TfrmGestionTurnos.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
