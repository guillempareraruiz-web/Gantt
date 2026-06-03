unit uErpFieldMapping;

// ============================================================================
// UI de mapeo ERP (perfil integrador): asocia cada columna custom del Backlog
// a una expresion SQL libre contra Sage (+ JOINs opcionales). El boton "Probar"
// ejecuta un SELECT de prueba contra el ERP antes de guardar.
//
// Persiste en FS_PL_Cfg_ErpFieldMap (via TErpFieldMapRepo). UI en DevExpress.
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  Data.Win.ADODB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxEdit, cxGrid, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxContainer, cxClasses, cxCustomData, cxData, cxDataStorage,
  cxNavigator, cxFilter, cxTextEdit, cxMemo, cxCheckBox, cxButtons,
  uErpTypes, uErpFieldMapRepo;

const
  BACKLOG_GRID_ID = 'BACKLOG';

type
  TMapRow = record
    FieldKey: string;
    Caption: string;
    AppliesToNivel: Integer;
    SqlExpression: string;
    SqlJoins: string;
    Activo: Boolean;
    Mapped: Boolean;
  end;

  TfrmErpFieldMapping = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TcxButton;
    grdCols: TcxGrid;
    tvCols: TcxGridTableView;
    lvCols: TcxGridLevel;
    colCaption: TcxGridColumn;
    colFieldKey: TcxGridColumn;
    colErp: TcxGridColumn;
    colExpr: TcxGridColumn;
    pnlEdit: TPanel;
    lblColSel: TLabel;
    lblExpr: TLabel;
    lblJoins: TLabel;
    edtExpr: TcxTextEdit;
    memJoins: TcxMemo;
    chkActivo: TcxCheckBox;
    btnProbar: TcxButton;
    btnGuardar: TcxButton;
    btnQuitar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvColsFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure btnProbarClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
  private
    FRepo: TErpFieldMapRepo;
    FRows: TList<TMapRow>;
    function EmpresaCode: SmallInt;
    procedure LoadRows;
    procedure RefreshGrid;
    procedure ShowDetail(AIndex: Integer);
    procedure EnableDetail(AEnable: Boolean);
    function SelectedIndex: Integer;
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uErpReaderFactory, uErpReader, uLogin, uHelpViewer;

class procedure TfrmErpFieldMapping.Execute;
var
  F: TfrmErpFieldMapping;
begin
  F := TfrmErpFieldMapping.Create(Application);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

function TfrmErpFieldMapping.EmpresaCode: SmallInt;
begin
  Result := DMPlanner.CodigoEmpresa;
end;

procedure TfrmErpFieldMapping.FormCreate(Sender: TObject);
begin
  FRepo := TErpFieldMapRepo.Create(DMPlanner.ADOConnection, EmpresaCode);
  FRows := TList<TMapRow>.Create;
  LoadRows;
  RefreshGrid;
  EnableDetail(False);
  THelpViewer.InstallHelp(Self, 'uErpFieldMapping', 'Mapeo de campos ERP');
end;

procedure TfrmErpFieldMapping.FormDestroy(Sender: TObject);
begin
  FRows.Free;
  FRepo.Free;
end;

procedure TfrmErpFieldMapping.LoadRows;
var
  Q: TADOQuery;
  Maps: TArray<TErpFieldMap>;
  Row: TMapRow;
  I: Integer;
begin
  FRows.Clear;
  Maps := FRepo.LoadAll(BACKLOG_GRID_ID);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ColumnKey, Caption, AppliesToNivel ' +
      'FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''' +
      '  AND IsCustomField = 1 AND Activo = 1 ' +
      'ORDER BY OrderDefault, ColumnKey';
    Q.Open;
    while not Q.Eof do
    begin
      Row := Default(TMapRow);
      Row.FieldKey := Q.FieldByName('ColumnKey').AsString;
      Row.Caption  := Q.FieldByName('Caption').AsString;
      if Q.FieldByName('AppliesToNivel').IsNull then
        Row.AppliesToNivel := 0
      else
        Row.AppliesToNivel := Q.FieldByName('AppliesToNivel').AsInteger;
      Row.Mapped := False;
      for I := 0 to High(Maps) do
        if SameText(Maps[I].FieldKey, Row.FieldKey) then
        begin
          Row.SqlExpression := Maps[I].SqlExpression;
          Row.SqlJoins      := Maps[I].SqlJoins;
          Row.Activo        := Maps[I].Activo;
          Row.Mapped        := True;
          Break;
        end;
      FRows.Add(Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmErpFieldMapping.RefreshGrid;
var
  I: Integer;
  Row: TMapRow;
  EstadoTxt: string;
begin
  tvCols.BeginUpdate;
  try
    tvCols.DataController.RecordCount := FRows.Count;
    for I := 0 to FRows.Count - 1 do
    begin
      Row := FRows[I];
      tvCols.DataController.Values[I, colCaption.Index]  := Row.Caption;
      tvCols.DataController.Values[I, colFieldKey.Index] := Row.FieldKey;
      if Row.Mapped and Row.Activo then EstadoTxt := 'S'#237
      else if Row.Mapped then EstadoTxt := '(inactivo)'
      else EstadoTxt := '-';
      tvCols.DataController.Values[I, colErp.Index]  := EstadoTxt;
      tvCols.DataController.Values[I, colExpr.Index] := Row.SqlExpression;
    end;
  finally
    tvCols.EndUpdate;
  end;
end;

function TfrmErpFieldMapping.SelectedIndex: Integer;
begin
  Result := tvCols.DataController.FocusedRecordIndex;
  if (Result < 0) or (Result >= FRows.Count) then Result := -1;
end;

procedure TfrmErpFieldMapping.tvColsFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
begin
  ShowDetail(SelectedIndex);
end;

procedure TfrmErpFieldMapping.ShowDetail(AIndex: Integer);
var
  Row: TMapRow;
begin
  if (AIndex < 0) or (AIndex >= FRows.Count) then
  begin
    EnableDetail(False);
    Exit;
  end;
  Row := FRows[AIndex];
  lblColSel.Caption := 'Columna: ' + Row.Caption + '  (' + Row.FieldKey + ')';
  edtExpr.Text := Row.SqlExpression;
  memJoins.Text := Row.SqlJoins;
  chkActivo.Checked := (not Row.Mapped) or Row.Activo;
  EnableDetail(True);
end;

procedure TfrmErpFieldMapping.EnableDetail(AEnable: Boolean);
begin
  edtExpr.Enabled    := AEnable;
  memJoins.Enabled   := AEnable;
  chkActivo.Enabled  := AEnable;
  btnProbar.Enabled  := AEnable;
  btnGuardar.Enabled := AEnable;
  btnQuitar.Enabled  := AEnable;
  if not AEnable then
  begin
    lblColSel.Caption := '(seleccione una columna)';
    edtExpr.Text := '';
    memJoins.Text := '';
    chkActivo.Checked := True;
  end;
end;

procedure TfrmErpFieldMapping.btnProbarClick(Sender: TObject);
var
  Reader: IErpReader;
  Res: string;
  Idx: Integer;
begin
  if Trim(edtExpr.Text) = '' then
  begin
    ShowMessage('Introduce una expresi'#243'n SQL antes de probar.');
    Exit;
  end;
  Idx := SelectedIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecciona una columna antes de probar.');
    Exit;
  end;
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    ShowMessage('No hay un ERP activo configurado para probar.');
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    try
      // El nivel de la columna decide la tabla de prueba (OF/OT/OP).
      Res := Reader.ProbarExpresionSql(Trim(edtExpr.Text), Trim(memJoins.Text),
        FRows[Idx].AppliesToNivel);
    except
      on E: Exception do
        Res := 'ERROR: ' + E.Message;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  ShowMessage(Res);
end;

procedure TfrmErpFieldMapping.btnGuardarClick(Sender: TObject);
var
  Idx: Integer;
  Row: TMapRow;
  M: TErpFieldMap;
begin
  Idx := SelectedIndex;
  if Idx < 0 then Exit;
  if Trim(edtExpr.Text) = '' then
  begin
    ShowMessage('La expresi'#243'n SQL no puede estar vac'#237'a. ' +
      'Para desvincular el campo del ERP, usa "Quitar mapeo".');
    Exit;
  end;
  Row := FRows[Idx];

  M.GridId         := BACKLOG_GRID_ID;
  M.FieldKey       := Row.FieldKey;
  M.ErpSource      := 'SAGE200';
  M.SqlExpression  := Trim(edtExpr.Text);
  M.SqlJoins       := Trim(memJoins.Text);
  M.AppliesToNivel := Row.AppliesToNivel;
  M.Activo         := chkActivo.Checked;
  FRepo.Save(M, CurrentSession.Login);

  LoadRows;
  RefreshGrid;
  if Idx < tvCols.DataController.RecordCount then
    tvCols.DataController.FocusedRecordIndex := Idx;
  ShowMessage('Mapeo guardado.');
end;

procedure TfrmErpFieldMapping.btnQuitarClick(Sender: TObject);
var
  Idx: Integer;
  Row: TMapRow;
begin
  Idx := SelectedIndex;
  if Idx < 0 then Exit;
  Row := FRows[Idx];
  if not Row.Mapped then
  begin
    ShowMessage('Esta columna no tiene mapeo ERP.');
    Exit;
  end;
  if MessageDlg('?Quitar el mapeo ERP de "' + Row.Caption + '"? ' +
       'El campo seguir'#225' rellen'#225'ndose solo manualmente.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FRepo.Delete(BACKLOG_GRID_ID, Row.FieldKey);
  LoadRows;
  RefreshGrid;
  EnableDetail(False);
end;

end.
