unit uUtillajePicker;

// Modal de seleccion de utillaje contra FS_PL_Utillaje (solo Activo = 1).
// Uso:
//   if TfrmUtillajePicker.Execute(Codigo, Descripcion) then ...

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
  uUtillajeTypes, uUtillajesRepo, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus,
  dxSkinSilver, dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008,
  dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;

type
  TfrmUtillajePicker = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblFiltro: TLabel;
    pnlFiltro: TPanel;
    edFiltro: TEdit;
    btnLimpiar: TButton;
    gridUtil: TcxGrid;
    tvUtil: TcxGridTableView;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    colTipo: TcxGridColumn;
    colUbicacion: TcxGridColumn;
    lvUtil: TcxGridLevel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure edFiltroChange(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure tvUtilDblClick(Sender: TObject);
  private
    FRepo: TUtillajesRepo;
    FAll: TArray<TUtillaje>;
    FCodigoSeleccionado: string;
    FDescSeleccionada: string;
    procedure LoadAll;
    procedure ApplyFilter(const AText: string);
  public
    class function Execute(out ACodigo, ADescripcion: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmUtillajePicker.Execute(out ACodigo,
  ADescripcion: string): Boolean;
var
  F: TfrmUtillajePicker;
begin
  ACodigo := '';
  ADescripcion := '';
  F := TfrmUtillajePicker.Create(Application);
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

procedure TfrmUtillajePicker.FormCreate(Sender: TObject);
begin
  FRepo := TUtillajesRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
end;

procedure TfrmUtillajePicker.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
end;

procedure TfrmUtillajePicker.FormShow(Sender: TObject);
begin
  LoadAll;
  ApplyFilter('');
  if edFiltro.CanFocus then edFiltro.SetFocus;
end;

procedure TfrmUtillajePicker.LoadAll;
begin
  FAll := FRepo.LoadActive;
end;

procedure TfrmUtillajePicker.ApplyFilter(const AText: string);
var
  I, Row: Integer;
  Filtro: string;
  Match: Boolean;
  U: TUtillaje;
begin
  Filtro := LowerCase(Trim(AText));
  tvUtil.BeginUpdate;
  try
    tvUtil.DataController.RecordCount := 0;
    Row := 0;
    for I := 0 to High(FAll) do
    begin
      U := FAll[I];
      if Filtro = '' then
        Match := True
      else
        Match := (Pos(Filtro, LowerCase(U.Codigo)) > 0) or
                 (Pos(Filtro, LowerCase(U.Descripcion)) > 0) or
                 (Pos(Filtro, LowerCase(U.Tipo)) > 0);
      if not Match then Continue;
      tvUtil.DataController.RecordCount := Row + 1;
      tvUtil.DataController.Values[Row, colCodigo.Index]      := U.Codigo;
      tvUtil.DataController.Values[Row, colDescripcion.Index] := U.Descripcion;
      tvUtil.DataController.Values[Row, colTipo.Index]        := U.Tipo;
      tvUtil.DataController.Values[Row, colUbicacion.Index]   := U.Ubicacion;
      Inc(Row);
    end;
    if tvUtil.DataController.RecordCount > 0 then
      tvUtil.Controller.FocusedRecordIndex := 0;
  finally
    tvUtil.EndUpdate;
  end;
end;

procedure TfrmUtillajePicker.edFiltroChange(Sender: TObject);
begin
  ApplyFilter(edFiltro.Text);
end;

procedure TfrmUtillajePicker.btnLimpiarClick(Sender: TObject);
begin
  edFiltro.Text := '';
  ApplyFilter('');
end;

procedure TfrmUtillajePicker.btnOKClick(Sender: TObject);
var
  Idx: Integer;
  V: Variant;
begin
  Idx := tvUtil.Controller.FocusedRecordIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecciona un utillaje.');
    Exit;
  end;
  V := tvUtil.DataController.Values[Idx, colCodigo.Index];
  if VarIsNull(V) or VarIsEmpty(V) then
  begin
    ShowMessage('Utillaje no v'#225'lido.');
    Exit;
  end;
  FCodigoSeleccionado := VarToStr(V);
  V := tvUtil.DataController.Values[Idx, colDescripcion.Index];
  if VarIsNull(V) or VarIsEmpty(V) then FDescSeleccionada := ''
  else FDescSeleccionada := VarToStr(V);
  ModalResult := mrOk;
end;

procedure TfrmUtillajePicker.tvUtilDblClick(Sender: TObject);
begin
  if tvUtil.Controller.FocusedRecordIndex >= 0 then
    btnOKClick(nil);
end;

end.
