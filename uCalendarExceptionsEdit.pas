unit uCalendarExceptionsEdit;

// ============================================================================
// Editor de excepciones (festivos, puentes, dias especiales) de un calendario.
// Lista las excepciones existentes y permite alta/edicion/eliminacion.
// La alta/edicion es un mini-dialog inline (fecha + tipo + horas si parcial).
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids,
  uCalendarsRepo;

type
  TfrmCalendarExceptionsEdit = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblCalendarNombre: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnEdit: TButton;
    btnDel: TButton;
    grdExcepciones: TStringGrid;
    procedure FormShow(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure grdExcepcionesDblClick(Sender: TObject);
  private
    FRepo: TCalendarsRepo;
    FCodigoEmpresa: SmallInt;
    FCalendarId: Integer;
    FCalendarNombre: string;
    FExceptionIds: TArray<Integer>;
    procedure Reload;
    function SelectedId: Integer;
  public
    class function Execute(ARepo: TCalendarsRepo; ACodigoEmpresa: SmallInt;
      ACalendarId: Integer; const ACalendarNombre: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uCalendarExceptionEditDialog;

class function TfrmCalendarExceptionsEdit.Execute(ARepo: TCalendarsRepo;
  ACodigoEmpresa: SmallInt; ACalendarId: Integer;
  const ACalendarNombre: string): Boolean;
var
  F: TfrmCalendarExceptionsEdit;
begin
  F := TfrmCalendarExceptionsEdit.Create(Application);
  try
    F.FRepo := ARepo;
    F.FCodigoEmpresa := ACodigoEmpresa;
    F.FCalendarId := ACalendarId;
    F.FCalendarNombre := ACalendarNombre;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmCalendarExceptionsEdit.FormShow(Sender: TObject);
begin
  lblCalendarNombre.Caption := FCalendarNombre;
  grdExcepciones.ColCount := 4;
  grdExcepciones.RowCount := 2;
  grdExcepciones.FixedRows := 1;
  grdExcepciones.Cells[0, 0] := 'Fecha';
  grdExcepciones.Cells[1, 0] := 'Tipo';
  grdExcepciones.Cells[2, 0] := 'Horario';
  grdExcepciones.Cells[3, 0] := 'Descripci'#243'n';
  grdExcepciones.ColWidths[0] := 100;
  grdExcepciones.ColWidths[1] := 90;
  grdExcepciones.ColWidths[2] := 130;
  grdExcepciones.ColWidths[3] := 360;
  Reload;
end;

procedure TfrmCalendarExceptionsEdit.Reload;
var
  Items: TArray<TCalendarExceptionRec>;
  i: Integer;
  Tipo, Hora: string;
begin
  Items := FRepo.LoadExceptions(FCodigoEmpresa, FCalendarId);
  SetLength(FExceptionIds, Length(Items));
  if Length(Items) = 0 then
  begin
    grdExcepciones.RowCount := 2;
    grdExcepciones.Cells[0, 1] := '';
    grdExcepciones.Cells[1, 1] := '(sin excepciones)';
    grdExcepciones.Cells[2, 1] := '';
    grdExcepciones.Cells[3, 1] := '';
    Exit;
  end;
  grdExcepciones.RowCount := Length(Items) + 1;
  for i := 0 to High(Items) do
  begin
    FExceptionIds[i] := Items[i].ExceptionId;
    grdExcepciones.Cells[0, i + 1] := FormatDateTime('dddd dd/mm/yyyy', Items[i].Fecha);
    if Items[i].EsLaborable then
    begin
      Tipo := 'Laborable parcial';
      Hora := Format('%s - %s',
        [FormatDateTime('hh:nn', Items[i].HoraInicio),
         FormatDateTime('hh:nn', Items[i].HoraFin)]);
    end
    else
    begin
      Tipo := 'Festivo / cerrado';
      Hora := '';
    end;
    grdExcepciones.Cells[1, i + 1] := Tipo;
    grdExcepciones.Cells[2, i + 1] := Hora;
    grdExcepciones.Cells[3, i + 1] := Items[i].Descripcion;
  end;
end;

function TfrmCalendarExceptionsEdit.SelectedId: Integer;
var
  Row: Integer;
begin
  Result := -1;
  Row := grdExcepciones.Row - 1;
  if (Row < 0) or (Row > High(FExceptionIds)) then Exit;
  Result := FExceptionIds[Row];
end;

procedure TfrmCalendarExceptionsEdit.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmCalendarExceptionsEdit.btnAddClick(Sender: TObject);
begin
  if TfrmCalendarExceptionEditDialog.Execute(FRepo, FCodigoEmpresa,
       FCalendarId, -1) then
    Reload;
end;

procedure TfrmCalendarExceptionsEdit.btnEditClick(Sender: TObject);
var
  Eid: Integer;
begin
  Eid := SelectedId;
  if Eid < 0 then Exit;
  if TfrmCalendarExceptionEditDialog.Execute(FRepo, FCodigoEmpresa,
       FCalendarId, Eid) then
    Reload;
end;

procedure TfrmCalendarExceptionsEdit.btnDelClick(Sender: TObject);
var
  Eid: Integer;
begin
  Eid := SelectedId;
  if Eid < 0 then Exit;
  if MessageDlg('Eliminar la excepci'#243'n seleccionada?',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
    FRepo.DeleteException(FCodigoEmpresa, Eid);
    Reload;
  except
    on E: Exception do
      ShowMessage('Error al eliminar: ' + E.Message);
  end;
end;

procedure TfrmCalendarExceptionsEdit.grdExcepcionesDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

end.
