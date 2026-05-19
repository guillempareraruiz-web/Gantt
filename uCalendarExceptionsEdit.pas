unit uCalendarExceptionsEdit;

// ============================================================================
// Editor de excepciones (festivos, puentes, dias especiales) de un calendario.
// Grid DevExpress (cxGrid) con multiselect NATIU via CheckBoxVisibility:
//   - cbvDataRow + cbvColumnHeader habiliten checkbox per fila i al header.
//   - Controller.SelectedRecords dona accs a les files marcades.
// Doc: docs/design/ExcepcionesGrid.md
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, System.DateUtils, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxClasses, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit,
  cxNavigator, cxGridLevel, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGridCustomView, cxGrid,
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
    btnDelSelected: TButton;
    lblTotales: TLabel;
    grdExc: TcxGrid;
    grdExcView: TcxGridDBTableView;
    grdExcLevel: TcxGridLevel;
    colFecha: TcxGridDBColumn;
    colTipo: TcxGridDBColumn;
    colHorario: TcxGridDBColumn;
    colDescripcion: TcxGridDBColumn;
    cdsExc: TClientDataSet;
    dsExc: TDataSource;
    procedure FormShow(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnDelSelectedClick(Sender: TObject);
    procedure grdExcViewDblClick(Sender: TObject);
  private
    FRepo: TCalendarsRepo;
    FCodigoEmpresa: SmallInt;
    FCalendarId: Integer;
    FCalendarNombre: string;
    procedure BuildDataset;
    procedure Reload;
    function SelectedId: Integer;
    procedure UpdateTotalesLabel;
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
  BuildDataset;
  Reload;
end;

procedure TfrmCalendarExceptionsEdit.BuildDataset;
begin
  cdsExc.Close;
  cdsExc.FieldDefs.Clear;
  cdsExc.FieldDefs.Add('ExceptionId', ftInteger);
  cdsExc.FieldDefs.Add('Fecha', ftDate);
  cdsExc.FieldDefs.Add('Tipo', ftString, 30);
  cdsExc.FieldDefs.Add('Horario', ftString, 20);
  cdsExc.FieldDefs.Add('Descripcion', ftString, 200);
  cdsExc.FieldDefs.Add('EsLaborable', ftBoolean);
  cdsExc.CreateDataSet;
end;

procedure TfrmCalendarExceptionsEdit.Reload;
var
  Items: TArray<TCalendarExceptionRec>;
  i: Integer;
  Tipo, Hora: string;
begin
  cdsExc.DisableControls;
  try
    cdsExc.EmptyDataSet;
    Items := FRepo.LoadExceptions(FCodigoEmpresa, FCalendarId);
    for i := 0 to High(Items) do
    begin
      if Items[i].EsLaborable then
      begin
        Tipo := 'Pausa parcial';
        Hora := Format('%s - %s',
          [FormatDateTime('hh:nn', Items[i].HoraInicio),
           FormatDateTime('hh:nn', Items[i].HoraFin)]);
      end
      else
      begin
        Tipo := 'Festivo / cerrado';
        Hora := '';
      end;

      cdsExc.Append;
      cdsExc.FieldByName('ExceptionId').AsInteger := Items[i].ExceptionId;
      cdsExc.FieldByName('Fecha').AsDateTime := Items[i].Fecha;
      cdsExc.FieldByName('Tipo').AsString := Tipo;
      cdsExc.FieldByName('Horario').AsString := Hora;
      cdsExc.FieldByName('Descripcion').AsString := Items[i].Descripcion;
      cdsExc.FieldByName('EsLaborable').AsBoolean := Items[i].EsLaborable;
      cdsExc.Post;
    end;
    cdsExc.First;
  finally
    cdsExc.EnableControls;
  end;
  UpdateTotalesLabel;
end;

function TfrmCalendarExceptionsEdit.SelectedId: Integer;
begin
  Result := -1;
  if not cdsExc.Active or cdsExc.IsEmpty then Exit;
  Result := cdsExc.FieldByName('ExceptionId').AsInteger;
end;

procedure TfrmCalendarExceptionsEdit.UpdateTotalesLabel;
var
  NFest, NParc: Integer;
  BM: TBookmark;
begin
  NFest := 0;
  NParc := 0;
  if cdsExc.Active and not cdsExc.IsEmpty then
  begin
    BM := cdsExc.GetBookmark;
    cdsExc.DisableControls;
    try
      cdsExc.First;
      while not cdsExc.Eof do
      begin
        if cdsExc.FieldByName('EsLaborable').AsBoolean then
          Inc(NParc)
        else
          Inc(NFest);
        cdsExc.Next;
      end;
    finally
      if cdsExc.BookmarkValid(BM) then
        cdsExc.GotoBookmark(BM);
      cdsExc.FreeBookmark(BM);
      cdsExc.EnableControls;
    end;
  end;
  lblTotales.Caption := Format('Festivas: %d   Parciales: %d   Total: %d',
    [NFest, NParc, NFest + NParc]);
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

procedure TfrmCalendarExceptionsEdit.btnDelSelectedClick(Sender: TObject);
var
  N, i: Integer;
  RecIndex: Integer;
  Ids: TArray<Integer>;
  Borradas, Errores: Integer;
  IdFieldIdx: Integer;
begin
  N := grdExcView.Controller.SelectedRecordCount;
  if N = 0 then
  begin
    ShowMessage('No hay excepciones marcadas.');
    Exit;
  end;
  if MessageDlg(Format('Eliminar %d excepciones marcadas?', [N]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  // Recollim ids dels records seleccionats via DataController
  IdFieldIdx := grdExcView.DataController.GetItemByFieldName('ExceptionId').Index;
  SetLength(Ids, N);
  for i := 0 to N - 1 do
  begin
    RecIndex := grdExcView.Controller.SelectedRecords[i].RecordIndex;
    Ids[i] := grdExcView.DataController.Values[RecIndex, IdFieldIdx];
  end;

  Borradas := 0;
  Errores := 0;
  for i := 0 to High(Ids) do
  begin
    try
      FRepo.DeleteException(FCodigoEmpresa, Ids[i]);
      Inc(Borradas);
    except
      Inc(Errores);
    end;
  end;

  if Errores > 0 then
    ShowMessage(Format('Eliminadas: %d. Errores: %d.', [Borradas, Errores]));

  Reload;
end;

procedure TfrmCalendarExceptionsEdit.grdExcViewDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

end.
