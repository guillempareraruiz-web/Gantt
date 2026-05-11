unit uPedidoDetalle;

// ============================================================================
// Formulario modal de detalle de Pedido Cliente.
//
// NO conoce el ERP origen. Habla siempre con IErpReader (uErpReaderFactory).
// Si manana cambia Sage 200 por SAP, este form no se toca: solo se cambia la
// implementacion del reader.
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxContainer, cxClasses,
  cxFilter, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxScrollbarAnnotations, dxDateRanges,
  dxSkinsCore, dxSkinOffice2019Colorful, dxBarBuiltInMenu,
  uErpReader, uErpTypes;

type
  TfrmPedidoDetalle = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    splitter: TSplitter;
    pnlCabecera: TPanel;
    pnlLineas: TPanel;
    lblCabHeader: TLabel;
    lblLinHeader: TLabel;
    gridCabecera: TcxGrid;
    tvCabecera: TcxGridTableView;
    lvCabecera: TcxGridLevel;
    gridLineas: TcxGrid;
    tvLineas: TcxGridTableView;
    lvLineas: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormShow(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FEjercicio: SmallInt;
    FSerie: string;
    FNumero: Integer;
    procedure LoadCabecera(AReader: IErpReader);
    procedure LoadLineas(AReader: IErpReader);
    procedure AddColTV(AView: TcxGridTableView; const ACaption: string;
      AWidth: Integer);
  public
    class procedure Execute(AEjercicio: SmallInt; const ASerie: string;
      ANumero: Integer);
  end;

implementation

{$R *.dfm}

uses
  uErpReaderFactory;

class procedure TfrmPedidoDetalle.Execute(AEjercicio: SmallInt;
  const ASerie: string; ANumero: Integer);
var
  Frm: TfrmPedidoDetalle;
begin
  Frm := TfrmPedidoDetalle.Create(nil);
  try
    Frm.FEjercicio := AEjercicio;
    Frm.FSerie := ASerie;
    Frm.FNumero := ANumero;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmPedidoDetalle.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPedidoDetalle.AddColTV(AView: TcxGridTableView;
  const ACaption: string; AWidth: Integer);
var
  Col: TcxGridColumn;
begin
  Col := AView.CreateColumn;
  Col.Caption := ACaption;
  Col.Width := AWidth;
  Col.Options.Editing := False;
end;

procedure TfrmPedidoDetalle.FormShow(Sender: TObject);
var
  Reader: IErpReader;
begin
  Caption := Format('Detalle pedido %s/%d - ejercicio %d',
    [FSerie, FNumero, FEjercicio]);
  lblTitle.Caption := Format('Pedido %s/%d', [FSerie, FNumero]);

  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    ShowMessage('No hay ning'#250'n ERP activo configurado.');
    Exit;
  end;
  lblSubtitle.Caption := Format('Ejercicio %d - ERP: %s',
    [FEjercicio, Reader.GetSistemaNombre]);

  try
    LoadCabecera(Reader);
    LoadLineas(Reader);
  except
    on E: Exception do
      ShowMessage('Error leyendo el pedido: ' + E.Message);
  end;
end;

procedure TfrmPedidoDetalle.LoadCabecera(AReader: IErpReader);
var
  Cab: TPedidoCabecera;
  RowIdx: Integer;

  procedure Add(const ACaption: string; const AValue: Variant; AWidth: Integer);
  var
    ColIdx: Integer;
  begin
    ColIdx := tvCabecera.ColumnCount;
    AddColTV(tvCabecera, ACaption, AWidth);
    tvCabecera.DataController.Values[RowIdx, ColIdx] := AValue;
  end;

  function Opt(const S: string): Variant;
  begin
    if S = '' then Result := Null else Result := S;
  end;

  function OptD(D: TDateTime): Variant;
  begin
    if D = 0 then Result := Null else Result := D;
  end;

  function OptF(F: Double): Variant;
  begin
    if F = 0 then Result := Null else Result := F;
  end;

begin
  tvCabecera.BeginUpdate;
  try
    tvCabecera.ClearItems;
    tvCabecera.DataController.RecordCount := 0;

    Cab := AReader.ReadPedidoCabecera(FSerie, FNumero, FEjercicio);

    if not Cab.Encontrado then
    begin
      tvCabecera.DataController.RecordCount := 1;
      AddColTV(tvCabecera, '(sin datos)', 300);
      tvCabecera.DataController.Values[0, 0] := 'Pedido no encontrado en el ERP';
      Exit;
    end;

    tvCabecera.DataController.RecordCount := 1;
    RowIdx := 0;

    Add('Pedido',         Format('%s/%d', [Cab.SeriePedido, Cab.NumeroPedido]),  90);
    Add('F. Pedido',      OptD(Cab.FechaPedido),         100);
    Add('F. Tope',        OptD(Cab.FechaTope),           100);
    Add('Lineas',         Cab.NumeroLineas,               60);
    Add('Cliente',        Opt(Cab.CodigoCliente),         80);
    Add('Razon social',   Opt(Cab.RazonSocial),          220);
    Add('Nombre comerc.', Opt(Cab.NombreComercial),      180);
    Add('CIF/DNI',        Opt(Cab.CifDni),               100);
    Add('Domicilio',      Opt(Cab.Domicilio),            220);
    Add('CP',             Opt(Cab.CodigoPostal),          70);
    Add('Municipio',      Opt(Cab.Municipio),            140);
    Add('Provincia',      Opt(Cab.Provincia),            120);
    Add('Nacion',         Opt(Cab.Nacion),               100);
    Add('Forma pago',     Opt(Cab.FormaPago),            140);
    Add('Plazos',         Cab.NumeroPlazos,               50);
    Add('Divisa',         Opt(Cab.CodigoDivisa),          60);
    Add('F. cambio',      OptF(Cab.FactorCambio),         80);
    Add('Base imp.',      OptF(Cab.BaseImponible),       100);
    Add('Total IVA',      OptF(Cab.TotalIva),            100);
    Add('Importe liq.',   OptF(Cab.ImporteLiquido),      120);
    Add('Aprobado',       Cab.Aprobado,                   70);
    Add('Comentario',     Opt(Cab.Comentario),           300);
    Add('Comentarios',    Opt(Cab.Comentarios),          300);
  finally
    tvCabecera.EndUpdate;
  end;
end;

procedure TfrmPedidoDetalle.LoadLineas(AReader: IErpReader);
var
  Lineas: TArray<TPedidoLinea>;
  L: TPedidoLinea;
  I: Integer;
begin
  tvLineas.BeginUpdate;
  try
    tvLineas.ClearItems;
    tvLineas.DataController.RecordCount := 0;

    AddColTV(tvLineas, 'Orden',           50);
    AddColTV(tvLineas, 'Articulo',       110);
    AddColTV(tvLineas, 'Descripcion',    300);
    AddColTV(tvLineas, 'Almacen',         80);
    AddColTV(tvLineas, 'Unidades',        80);
    AddColTV(tvLineas, 'UM',              50);
    AddColTV(tvLineas, 'Precio',         100);
    AddColTV(tvLineas, '% Dto1',          70);
    AddColTV(tvLineas, '% Dto2',          70);
    AddColTV(tvLineas, 'Importe',        110);
    AddColTV(tvLineas, 'F. servicio',    110);
    AddColTV(tvLineas, 'F. necesaria',   110);
    AddColTV(tvLineas, 'Unid. servidas', 100);
    AddColTV(tvLineas, 'Unid. pdtes',    100);
    AddColTV(tvLineas, 'Comentario',     240);

    Lineas := AReader.ReadPedidoLineas(FSerie, FNumero, FEjercicio);

    for I := 0 to High(Lineas) do
    begin
      L := Lineas[I];
      tvLineas.DataController.RecordCount := I + 1;
      tvLineas.DataController.Values[I, 0]  := L.Orden;
      tvLineas.DataController.Values[I, 1]  := L.CodigoArticulo;
      tvLineas.DataController.Values[I, 2]  := L.DescripcionArticulo;
      tvLineas.DataController.Values[I, 3]  := L.CodigoAlmacen;
      tvLineas.DataController.Values[I, 4]  := L.Unidades;
      tvLineas.DataController.Values[I, 5]  := L.UnidadMedida;
      tvLineas.DataController.Values[I, 6]  := L.Precio;
      tvLineas.DataController.Values[I, 7]  := L.Descuento1;
      tvLineas.DataController.Values[I, 8]  := L.Descuento2;
      tvLineas.DataController.Values[I, 9]  := L.ImporteLiquido;
      if L.FechaServicio <> 0 then
        tvLineas.DataController.Values[I, 10] := L.FechaServicio;
      if L.FechaNecesaria <> 0 then
        tvLineas.DataController.Values[I, 11] := L.FechaNecesaria;
      tvLineas.DataController.Values[I, 12] := L.UnidadesServidas;
      tvLineas.DataController.Values[I, 13] := L.UnidadesPendientes;
      tvLineas.DataController.Values[I, 14] := L.Comentario;
    end;
  finally
    tvLineas.EndUpdate;
  end;
end;

end.
