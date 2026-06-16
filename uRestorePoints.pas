unit uRestorePoints;
// Dialogo de PUNTOS DE RESTAURACION del plan de un proyecto.
// Lista los snapshots (FS_PL_Snapshot via TSnapshotRepo), permite crear puntos
// manuales, eliminar y restaurar (con doble confirmacion). Si el usuario
// restaura, el dialogo cierra con mrOk para que el caller recargue el plan.
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs,
  uSnapshotRepo;

type
  TfrmRestorePoints = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lvPuntos: TListView;
    pnlBottom: TPanel;
    btnCrearManual: TButton;
    btnEliminar: TButton;
    btnRestaurar: TButton;
    btnCerrar: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCrearManualClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure btnRestaurarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FRepo: TSnapshotRepo;
    FProjectId: Integer;
    FRestaurado: Boolean;
    procedure Poblar;
    function SnapshotSeleccionado(out AInfo: TSnapshotInfo): Boolean;
  public
    // Abre el dialogo. Devuelve True si el usuario restauro un punto (el caller
    // debe recargar el plan del proyecto).
    class function Ejecutar(AOwner: TComponent; ARepo: TSnapshotRepo;
      AProjectId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmRestorePoints.Ejecutar(AOwner: TComponent;
  ARepo: TSnapshotRepo; AProjectId: Integer): Boolean;
var
  F: TfrmRestorePoints;
begin
  F := TfrmRestorePoints.Create(AOwner);
  try
    F.FRepo := ARepo;
    F.FProjectId := AProjectId;
    F.ShowModal;
    Result := F.FRestaurado;
  finally
    F.Free;
  end;
end;

procedure TfrmRestorePoints.Poblar;
var
  Lista: TArray<TSnapshotInfo>;
  Info: TSnapshotInfo;
  Li: TListItem;
begin
  lvPuntos.Items.BeginUpdate;
  try
    lvPuntos.Items.Clear;
    if FRepo = nil then Exit;
    Lista := FRepo.GetList(FProjectId);
    for Info in Lista do
    begin
      Li := lvPuntos.Items.Add;
      Li.Caption := FormatDateTime('dd/mm/yyyy hh:nn', Info.FechaCreacion);
      if SameText(Info.Tipo, 'AUTO') then
        Li.SubItems.Add('Autom'#225'tico')
      else
        Li.SubItems.Add('Manual');
      Li.SubItems.Add(IntToStr(Info.NodeCount));
      Li.SubItems.Add(Info.Descripcion);
      Li.SubItems.Add(Info.CreadoPor);
      Li.Data := Pointer(Info.SnapshotId);
    end;
  finally
    lvPuntos.Items.EndUpdate;
  end;
  if lvPuntos.Items.Count > 0 then
    lvPuntos.Items[0].Selected := True;
  btnRestaurar.Enabled := lvPuntos.Items.Count > 0;
  btnEliminar.Enabled := lvPuntos.Items.Count > 0;
end;

function TfrmRestorePoints.SnapshotSeleccionado(
  out AInfo: TSnapshotInfo): Boolean;
var
  Lista: TArray<TSnapshotInfo>;
  Info: TSnapshotInfo;
  Sel: Integer;
begin
  Result := False;
  if (lvPuntos.Selected = nil) or (FRepo = nil) then Exit;
  Sel := Integer(lvPuntos.Selected.Data);
  Lista := FRepo.GetList(FProjectId);
  for Info in Lista do
    if Info.SnapshotId = Sel then
    begin
      AInfo := Info;
      Exit(True);
    end;
end;

procedure TfrmRestorePoints.btnCrearManualClick(Sender: TObject);
var
  Nombre: string;
begin
  if FRepo = nil then Exit;
  Nombre := 'Punto ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
  if not InputQuery('Crear punto de restauraci'#243'n',
    'Descripci'#243'n del punto:', Nombre) then Exit;
  if Trim(Nombre) = '' then Exit;
  Screen.Cursor := crHourGlass;
  try
    if FRepo.CrearManual(FProjectId, Nombre, '') then
      Poblar
    else
      ShowMessage('No se pudo crear el punto de restauraci'#243'n.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmRestorePoints.btnEliminarClick(Sender: TObject);
var
  Info: TSnapshotInfo;
begin
  if not SnapshotSeleccionado(Info) then Exit;
  if MessageDlg(Format(''#191'Eliminar el punto de restauraci'#243'n del %s?',
    [FormatDateTime('dd/mm/yyyy hh:nn', Info.FechaCreacion)]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FRepo.Borrar(Info.SnapshotId);
  Poblar;
end;

procedure TfrmRestorePoints.btnRestaurarClick(Sender: TObject);
var
  Info: TSnapshotInfo;
  Err: string;
begin
  if not SnapshotSeleccionado(Info) then Exit;

  // Doble confirmacion: restaurar REEMPLAZA el plan actual.
  if MessageDlg(Format(
    'Vas a RESTAURAR el plan al estado del %s (%d nodos).' + sLineBreak +
    'Esto REEMPLAZA el plan actual del proyecto.' + sLineBreak + sLineBreak +
    'Se guardara automaticamente un punto de seguridad del estado actual ' +
    'antes de restaurar.' + sLineBreak + sLineBreak + #191'Continuar?',
    [FormatDateTime('dd/mm/yyyy hh:nn', Info.FechaCreacion), Info.NodeCount]),
    mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  if MessageDlg('Confirmaci'#243'n final: '#191'restaurar este punto y reemplazar el ' +
    'plan actual?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    Err := FRepo.Restaurar(Info.SnapshotId, FProjectId);
  finally
    Screen.Cursor := crDefault;
  end;

  if Err <> '' then
  begin
    ShowMessage('No se ha restaurado: ' + Err);
    Exit;
  end;

  FRestaurado := True;
  ShowMessage('Plan restaurado correctamente.');
  ModalResult := mrOk;
end;

procedure TfrmRestorePoints.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmRestorePoints.FormShow(Sender: TObject);
begin
  FRestaurado := False;
  Poblar;
end;

procedure TfrmRestorePoints.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end;
end;

end.
