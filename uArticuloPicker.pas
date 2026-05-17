unit uArticuloPicker;

// ============================================================================
// Selector modal de art'iculo. Recibe un IErpReader y muestra un grid con
// b'usqueda incremental. Devuelve el c'odigo y descripci'on del art'iculo
// seleccionado.
//
// Uso:
//   if TfrmArticuloPicker.Execute(Reader, Codigo, Descripcion) then ...
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, dxCore,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxClasses, cxGridCustomView, cxGrid, cxDBData,
  uErpReader, uErpTypes;

type
  TfrmArticuloPicker = class(TForm)
    pnlTop: TPanel;
    lblFiltro: TLabel;
    edFiltro: TEdit;
    btnBuscar: TButton;
    grdArticulos: TcxGrid;
    grdArticulosView: TcxGridDBTableView;
    grdArticulosLevel: TcxGridLevel;
    pnlBotones: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    cdsArticulos: TClientDataSet;
    dsArticulos: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edFiltroKeyPress(Sender: TObject; var Key: Char);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure grdArticulosViewDblClick(Sender: TObject);
  private
    FReader: IErpReader;
    FCodigoSeleccionado: string;
    FDescripcionSeleccionada: string;
    procedure CargarArticulos(const AFiltro: string);
  public
    class function Execute(const AReader: IErpReader;
      out ACodigo, ADescripcion: string): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmArticuloPicker.Execute(const AReader: IErpReader;
  out ACodigo, ADescripcion: string): Boolean;
var
  Frm: TfrmArticuloPicker;
begin
  Frm := TfrmArticuloPicker.Create(nil);
  try
    Frm.FReader := AReader;
    Result := Frm.ShowModal = mrOk;
    if Result then
    begin
      ACodigo := Frm.FCodigoSeleccionado;
      ADescripcion := Frm.FDescripcionSeleccionada;
    end;
  finally
    Frm.Free;
  end;
end;

procedure TfrmArticuloPicker.FormCreate(Sender: TObject);
begin
  cdsArticulos.FieldDefs.Clear;
  cdsArticulos.FieldDefs.Add('Codigo', ftString, 30);
  cdsArticulos.FieldDefs.Add('Descripcion', ftString, 100);
  cdsArticulos.FieldDefs.Add('Tipo', ftString, 30);
  cdsArticulos.FieldDefs.Add('Familia', ftString, 30);
  cdsArticulos.FieldDefs.Add('UnidadMedida', ftString, 10);
  cdsArticulos.FieldDefs.Add('TieneFormula', ftBoolean);
  cdsArticulos.CreateDataSet;
end;

procedure TfrmArticuloPicker.FormShow(Sender: TObject);
begin
  if edFiltro.CanFocus then
    edFiltro.SetFocus;
end;

procedure TfrmArticuloPicker.edFiltroKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnBuscarClick(nil);
  end;
end;

procedure TfrmArticuloPicker.CargarArticulos(const AFiltro: string);
var
  Lista: TArray<TArticuloErp>;
  i: Integer;
begin
  cdsArticulos.DisableControls;
  try
    cdsArticulos.EmptyDataSet;
    if FReader = nil then Exit;
    Lista := FReader.ReadArticulos(AFiltro);
    for i := 0 to High(Lista) do
    begin
      cdsArticulos.Append;
      cdsArticulos.FieldByName('Codigo').AsString := Lista[i].Codigo;
      cdsArticulos.FieldByName('Descripcion').AsString := Lista[i].Descripcion;
      cdsArticulos.FieldByName('Tipo').AsString := Lista[i].TipoArticulo;
      cdsArticulos.FieldByName('Familia').AsString := Lista[i].CodigoFamilia;
      cdsArticulos.FieldByName('UnidadMedida').AsString := Lista[i].UnidadMedida;
      cdsArticulos.FieldByName('TieneFormula').AsBoolean := Lista[i].TieneFormula;
      cdsArticulos.Post;
    end;
    cdsArticulos.First;
  finally
    cdsArticulos.EnableControls;
  end;
  // Columnes nomes la primera vegada. CreateAllItems es idempotent si ja
  // existeixen i no duplica si no s'afegeixen FieldDefs nous. Per evitar
  // qualsevol problema, no toquem columnes despres del FormCreate.
  if grdArticulosView.ColumnCount = 0 then
  begin
    grdArticulosView.BeginUpdate;
    try
      grdArticulosView.DataController.CreateAllItems;
      for i := 0 to grdArticulosView.ColumnCount - 1 do
      begin
        grdArticulosView.Columns[i].Options.Editing := False;
        grdArticulosView.Columns[i].Options.Focusing := False;
      end;
    finally
      grdArticulosView.EndUpdate;
    end;
  end;
  grdArticulosView.ApplyBestFit;
end;

procedure TfrmArticuloPicker.btnBuscarClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    CargarArticulos(Trim(edFiltro.Text));
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmArticuloPicker.btnAceptarClick(Sender: TObject);
begin
  if cdsArticulos.IsEmpty then Exit;
  FCodigoSeleccionado := cdsArticulos.FieldByName('Codigo').AsString;
  FDescripcionSeleccionada := cdsArticulos.FieldByName('Descripcion').AsString;
  ModalResult := mrOk;
end;

procedure TfrmArticuloPicker.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmArticuloPicker.grdArticulosViewDblClick(Sender: TObject);
begin
  btnAceptarClick(nil);
end;

end.
