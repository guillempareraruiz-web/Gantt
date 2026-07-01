unit uDashboardConfig;

// ============================================================================
// Dialogo "Configurar tarjetas panel".
//
// Grid (cxGrid) con una fila por KPI:
//   Visible (checkbox) | Titulo | Descripcion | Categoria
//
// Sin botones Aceptar/Cancelar: los cambios se aplican EN DIRECTO. Cada vez que
// el usuario marca/desmarca "Visible", se invoca el callback AApply(Key, Visible)
// que el dashboard usa para mostrar/ocultar la card y persistir. Se cierra con
// la X del dialogo.
//
// Convenciones de la casa: borde de dialogo (bsDialog) y boton de ayuda (?) en
// el caption (biHelp).
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxData, cxDataStorage, cxEdit, cxNavigator, cxDBData,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxGrid, cxCheckBox, dxSkinsCore, cxContainer;

type
  // Un item de configuracion (lo aporta el dashboard).
  TDashCardInfo = record
    Key: string;
    Titulo: string;
    Descripcion: string;
    Categoria: string;
    Visible: Boolean;
  end;

  // Callback que aplica el cambio de visibilidad en directo.
  TApplyVisibleProc = procedure(const AKey: string; AVisible: Boolean) of object;

  TfrmDashboardConfig = class(TForm)
  private
    FGrid: TcxGrid;
    FView: TcxGridDBTableView;
    FLevel: TcxGridLevel;
    FDS: TDataSource;
    FCDS: TClientDataSet;
    FApply: TApplyVisibleProc;
    procedure BuildUI;
    procedure BuildDataset(const AItems: TArray<TDashCardInfo>);
    procedure VisibleFieldChanged(Sender: TField);
  public
    // Muestra el dialogo modal. AApply se invoca en cada cambio de visibilidad.
    class procedure Editar(AOwner: TComponent;
      const AItems: TArray<TDashCardInfo>; const AApply: TApplyVisibleProc);
  end;

implementation

{$R *.dfm}

class procedure TfrmDashboardConfig.Editar(AOwner: TComponent;
  const AItems: TArray<TDashCardInfo>; const AApply: TApplyVisibleProc);
var
  F: TfrmDashboardConfig;
begin
  F := TfrmDashboardConfig.Create(AOwner);
  try
    F.FApply := AApply;
    F.BuildUI;
    F.BuildDataset(AItems);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmDashboardConfig.BuildUI;
begin
  Caption := 'Configurar tarjetas panel';
  BorderStyle := bsDialog;          // borde de dialogo
  BorderIcons := [biSystemMenu, biHelp];  // boton de ayuda (?) en el caption
  Position := poOwnerFormCenter;
  ClientWidth := 640;
  ClientHeight := 380;

  FGrid := TcxGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.AlignWithMargins := True;
  FGrid.Margins.SetBounds(8, 8, 8, 8);

  FLevel := FGrid.Levels.Add;
  FView := FGrid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  FLevel.GridView := FView;

  FView.OptionsView.GroupByBox := False;
  FView.OptionsView.Indicator := True;
  FView.OptionsData.Editing := True;
  FView.OptionsData.Deleting := False;
  FView.OptionsData.Inserting := False;
  // CellSelect debe estar activo para poder entrar en edicion de la celda del
  // checkbox; ImmediateEditor hace que un solo clic active el editor.
  FView.OptionsSelection.CellSelect := True;
  FView.OptionsBehavior.ImmediateEditor := True;
  FView.OptionsBehavior.FocusCellOnTab := True;
end;

procedure TfrmDashboardConfig.BuildDataset(const AItems: TArray<TDashCardInfo>);
var
  I: Integer;
  ColVis, ColTit, ColDesc, ColCat: TcxGridDBColumn;
begin
  FCDS := TClientDataSet.Create(Self);
  FCDS.FieldDefs.Add('Key', ftString, 40);
  FCDS.FieldDefs.Add('Visible', ftBoolean);
  FCDS.FieldDefs.Add('Titulo', ftString, 80);
  FCDS.FieldDefs.Add('Descripcion', ftString, 250);
  FCDS.FieldDefs.Add('Categoria', ftString, 40);
  FCDS.CreateDataSet;

  for I := 0 to High(AItems) do
  begin
    FCDS.Append;
    FCDS.FieldByName('Key').AsString := AItems[I].Key;
    FCDS.FieldByName('Visible').AsBoolean := AItems[I].Visible;
    FCDS.FieldByName('Titulo').AsString := AItems[I].Titulo;
    FCDS.FieldByName('Descripcion').AsString := AItems[I].Descripcion;
    FCDS.FieldByName('Categoria').AsString := AItems[I].Categoria;
    FCDS.Post;
  end;
  FCDS.First;

  FDS := TDataSource.Create(Self);
  FDS.DataSet := FCDS;
  FView.DataController.DataSource := FDS;

  // Columna Visible como checkbox; aplica el cambio en directo al editar.
  ColVis := FView.CreateColumn;
  ColVis.DataBinding.FieldName := 'Visible';
  ColVis.Caption := 'Visible';
  ColVis.PropertiesClass := TcxCheckBoxProperties;
  ColVis.Width := 70;
  ColVis.Options.Editing := True;   // esta columna SI es editable
  with ColVis.Properties as TcxCheckBoxProperties do
  begin
    DisplayChecked := 'S'#237;
    DisplayUnchecked := 'No';
    ImmediatePost := True;          // aplica al primer clic, sin confirmar
  end;
  // Aplicar en directo cuando cambia el valor del campo Visible (el checkbox
  // hace Post automatico del campo -> dispara OnChange del field).
  FCDS.FieldByName('Visible').OnChange := VisibleFieldChanged;

  ColTit := FView.CreateColumn;
  ColTit.DataBinding.FieldName := 'Titulo';
  ColTit.Caption := 'T'#237'tulo';
  ColTit.Width := 160;
  ColTit.Options.Editing := False;

  ColDesc := FView.CreateColumn;
  ColDesc.DataBinding.FieldName := 'Descripcion';
  ColDesc.Caption := 'Descripci'#243'n';
  ColDesc.Width := 300;
  ColDesc.Options.Editing := False;

  ColCat := FView.CreateColumn;
  ColCat.DataBinding.FieldName := 'Categoria';
  ColCat.Caption := 'Categor'#237'a';
  ColCat.Width := 90;
  ColCat.Options.Editing := False;
end;

procedure TfrmDashboardConfig.VisibleFieldChanged(Sender: TField);
begin
  // OnChange del campo Visible: el registro actual del dataset ya tiene el nuevo
  // valor. Aplicar en directo (mostrar/ocultar la card en el dashboard).
  if Assigned(FApply) then
    FApply(FCDS.FieldByName('Key').AsString, Sender.AsBoolean);
end;

end.
