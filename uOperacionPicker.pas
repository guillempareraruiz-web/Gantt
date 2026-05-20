unit uOperacionPicker;

// Modal de seleccion de operacion contra FS_PL_OperationType.
// Uso:
//   if TfrmOperacionPicker.Execute(Codigo, Descripcion) then ...

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmOperacionPicker = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblFiltro: TLabel;
    pnlFiltro: TPanel;
    edFiltro: TEdit;
    btnLimpiar: TButton;
    gridOps: TcxGrid;
    tvOps: TcxGridTableView;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    lvOps: TcxGridLevel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure edFiltroChange(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure tvOpsDblClick(Sender: TObject);
  private
    type
      TOpRow = record Codigo: string; Descripcion: string; end;
  private
    FAll: TArray<TOpRow>;
    FCodigoSeleccionado: string;
    FDescSeleccionada: string;
    procedure LoadAll;
    procedure ApplyFilter(const AText: string);
    function SelectedCodigo: string;
  public
    class function Execute(out ACodigo, ADescripcion: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmOperacionPicker.Execute(out ACodigo,
  ADescripcion: string): Boolean;
var
  F: TfrmOperacionPicker;
begin
  ACodigo := '';
  ADescripcion := '';
  F := TfrmOperacionPicker.Create(Application);
  try
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      ACodigo := F.FCodigoSeleccionado;
      ADescripcion := F.FDescSeleccionada;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmOperacionPicker.FormCreate(Sender: TObject);
begin
  // nada: dejamos para FormShow para tener el form ya visible
end;

procedure TfrmOperacionPicker.FormShow(Sender: TObject);
begin
  LoadAll;
  ApplyFilter('');
  if edFiltro.CanFocus then edFiltro.SetFocus;
end;

procedure TfrmOperacionPicker.LoadAll;
var
  Q: TADOQuery;
  L: TList<TOpRow>;
  R: TOpRow;
begin
  L := TList<TOpRow>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT Operacion, ISNULL(Descripcion, '''') AS Descripcion ' +
        'FROM FS_PL_OperationType ' +
        'WHERE CodigoEmpresa = :CE ' +
        'ORDER BY Operacion';
      Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        R.Codigo := Q.FieldByName('Operacion').AsString;
        R.Descripcion := Q.FieldByName('Descripcion').AsString;
        L.Add(R);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    FAll := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmOperacionPicker.ApplyFilter(const AText: string);
var
  I, Row: Integer;
  Filtro: string;
  Match: Boolean;
begin
  Filtro := LowerCase(Trim(AText));
  tvOps.BeginUpdate;
  try
    tvOps.DataController.RecordCount := 0;
    Row := 0;
    for I := 0 to High(FAll) do
    begin
      if Filtro = '' then
        Match := True
      else
        Match := (Pos(Filtro, LowerCase(FAll[I].Codigo)) > 0) or
                 (Pos(Filtro, LowerCase(FAll[I].Descripcion)) > 0);
      if not Match then Continue;
      tvOps.DataController.RecordCount := Row + 1;
      tvOps.DataController.Values[Row, colCodigo.Index]      := FAll[I].Codigo;
      tvOps.DataController.Values[Row, colDescripcion.Index] := FAll[I].Descripcion;
      Inc(Row);
    end;
    if tvOps.DataController.RecordCount > 0 then
      tvOps.Controller.FocusedRecordIndex := 0;
  finally
    tvOps.EndUpdate;
  end;
end;

procedure TfrmOperacionPicker.edFiltroChange(Sender: TObject);
begin
  ApplyFilter(edFiltro.Text);
end;

procedure TfrmOperacionPicker.btnLimpiarClick(Sender: TObject);
begin
  edFiltro.Text := '';
  ApplyFilter('');
end;

function TfrmOperacionPicker.SelectedCodigo: string;
var
  Idx: Integer;
  V: Variant;
begin
  Result := '';
  Idx := tvOps.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := tvOps.DataController.Values[Idx, colCodigo.Index];
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  Result := VarToStr(V);
end;

procedure TfrmOperacionPicker.btnOKClick(Sender: TObject);
var
  Idx: Integer;
  V: Variant;
begin
  Idx := tvOps.Controller.FocusedRecordIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecciona una operaci'#243'n.');
    Exit;
  end;
  V := tvOps.DataController.Values[Idx, colCodigo.Index];
  if VarIsNull(V) or VarIsEmpty(V) then
  begin
    ShowMessage('Operaci'#243'n no v'#225'lida.');
    Exit;
  end;
  FCodigoSeleccionado := VarToStr(V);
  V := tvOps.DataController.Values[Idx, colDescripcion.Index];
  if VarIsNull(V) or VarIsEmpty(V) then FDescSeleccionada := '' else FDescSeleccionada := VarToStr(V);
  ModalResult := mrOk;
end;

procedure TfrmOperacionPicker.tvOpsDblClick(Sender: TObject);
begin
  if tvOps.Controller.FocusedRecordIndex >= 0 then
    btnOKClick(nil);
end;

end.
