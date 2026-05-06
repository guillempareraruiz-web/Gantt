unit uVistaKanban;

{
  Form contenedor de TKanbanBoard.
  - Carga el layout de columnas / orden de tarjetas desde FS_PL_Cfg_UserPrefs
    (Module='Kanban', PrefKey='Layout') al abrir, lo guarda al cerrar.
  - Si no hay layout guardado, el TKanbanBoard ya crea las 4 columnas por defecto.
  - El estado del nodo (Pendiente/EnCurso/...) se persiste vía TNodeDataRepo
    al arrastrar tarjeta entre columnas mapeadas a estado (write-back ya existente).
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.JSON,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  uGanttTypes, uNodeDataRepo, uKanbanBoard, uPlanAutoSaver;

type
  TVistaKanbanForm = class(TForm)
    pnlToolbar: TPanel;
    lblCentro: TLabel;
    cbCentro: TComboBox;
    lblPrioridad: TLabel;
    cbPrioridad: TComboBox;
    lblArticulo: TLabel;
    edArticulo: TEdit;
    btnLimpiar: TButton;
    btnNuevaCol: TButton;
    btnRestaurar: TButton;
    pnlBoard: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cbCentroChange(Sender: TObject);
    procedure cbPrioridadChange(Sender: TObject);
    procedure edArticuloChange(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure btnNuevaColClick(Sender: TObject);
    procedure btnRestaurarClick(Sender: TObject);
  private const
    PREF_MODULE = 'Kanban';
    PREF_KEY_LAYOUT = 'Layout';
  private
    FNodeRepo: TNodeDataRepo;
    FCentres: TArray<TCentreTreball>;
    FGetNodeTimes: TGetNodeTimesFunc;
    FGetNodeCentre: TGetNodeCentreFunc;
    FOnPlanModified: TPlanModifiedProc;
    FBoard: TKanbanBoard;
    FLayoutDirty: Boolean;
    FApplyingFilters: Boolean;

    procedure BuildBoard;
    procedure PopulateCombos;
    procedure ApplyFilters;
    procedure OnBoardLayoutChanged(Sender: TObject);
    procedure OnBacklogMoreClick(Sender: TObject);
    procedure OnBoardCardMoved(Sender: TObject; const DataId: Integer;
      const OldState, NewState: TNodoEstado);
    procedure LoadBacklogFromDB;

    function SerializeLayout: string;
    procedure DeserializeLayout(const AJson: string);
    procedure LoadLayoutFromPrefs;
    procedure SaveLayoutToPrefs;
  public
    class procedure Execute(
      ANodeRepo: TNodeDataRepo;
      const ACentres: TArray<TCentreTreball>;
      AGetNodeTimes: TGetNodeTimesFunc;
      AGetNodeCentre: TGetNodeCentreFunc;
      AOnPlanModified: TPlanModifiedProc = nil);
  end;

implementation

{$R *.dfm}

uses
  Data.Win.ADODB,
  uUserPrefs, uDMPlanner, uBacklog;

{ ========================================================= }
{                       Execute                              }
{ ========================================================= }

class procedure TVistaKanbanForm.Execute(
  ANodeRepo: TNodeDataRepo;
  const ACentres: TArray<TCentreTreball>;
  AGetNodeTimes: TGetNodeTimesFunc;
  AGetNodeCentre: TGetNodeCentreFunc;
  AOnPlanModified: TPlanModifiedProc);
var
  Frm: TVistaKanbanForm;
begin
  Frm := TVistaKanbanForm.Create(nil);
  try
    Frm.FNodeRepo := ANodeRepo;
    Frm.FCentres := ACentres;
    Frm.FGetNodeTimes := AGetNodeTimes;
    Frm.FGetNodeCentre := AGetNodeCentre;
    Frm.FOnPlanModified := AOnPlanModified;

    Frm.BuildBoard;
    Frm.PopulateCombos;
    Frm.LoadLayoutFromPrefs;
    Frm.LoadBacklogFromDB;

    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

{ ========================================================= }
{                  Form lifecycle                            }
{ ========================================================= }

procedure TVistaKanbanForm.FormCreate(Sender: TObject);
begin
  FLayoutDirty := False;
  FApplyingFilters := False;
end;

procedure TVistaKanbanForm.FormDestroy(Sender: TObject);
begin
  // FBoard es Owner = Self, se libera con el form
end;

procedure TVistaKanbanForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FLayoutDirty then
    SaveLayoutToPrefs;
end;

{ ========================================================= }
{                  Build / Combos                            }
{ ========================================================= }

procedure TVistaKanbanForm.BuildBoard;
begin
  FBoard := TKanbanBoard.Create(Self);
  FBoard.Parent := pnlBoard;
  FBoard.Align := alClient;
  FBoard.SetGetNodeTimes(FGetNodeTimes);
  FBoard.SetGetNodeCentre(FGetNodeCentre);
  FBoard.OnLayoutChanged := OnBoardLayoutChanged;
  FBoard.OnBacklogMoreClick := OnBacklogMoreClick;
  FBoard.OnCardMoved := OnBoardCardMoved;
  FBoard.SetNodeRepo(FNodeRepo);
end;

procedure TVistaKanbanForm.PopulateCombos;
var
  I: Integer;
begin
  FApplyingFilters := True;
  try
    cbCentro.Items.BeginUpdate;
    try
      cbCentro.Items.Clear;
      cbCentro.Items.AddObject('(Todos)', TObject(-1));
      for I := 0 to High(FCentres) do
        cbCentro.Items.AddObject(FCentres[I].Titulo, TObject(FCentres[I].Id));
      cbCentro.ItemIndex := 0;
    finally
      cbCentro.Items.EndUpdate;
    end;

    cbPrioridad.Items.BeginUpdate;
    try
      cbPrioridad.Items.Clear;
      cbPrioridad.Items.AddObject('(Todas)', TObject(-1));
      cbPrioridad.Items.AddObject('Alta',   TObject(0));
      cbPrioridad.Items.AddObject('Media',  TObject(1));
      cbPrioridad.Items.AddObject('Baja',   TObject(2));
      cbPrioridad.ItemIndex := 0;
    finally
      cbPrioridad.Items.EndUpdate;
    end;
  finally
    FApplyingFilters := False;
  end;
end;

{ ========================================================= }
{                       Filtros                              }
{ ========================================================= }

procedure TVistaKanbanForm.ApplyFilters;
var
  CentreId, Prioridad: Integer;
  Articulo: string;
begin
  if FBoard = nil then Exit;

  Articulo := Trim(edArticulo.Text);

  CentreId := -1;
  if cbCentro.ItemIndex > 0 then
    CentreId := Integer(cbCentro.Items.Objects[cbCentro.ItemIndex]);

  Prioridad := -1;
  if cbPrioridad.ItemIndex > 0 then
    Prioridad := Integer(cbPrioridad.Items.Objects[cbPrioridad.ItemIndex]);

  // Solo un filtro a la vez (es lo que soporta TKanbanBoard hoy).
  // Prioridad: Articulo > Centre > Prioridad.
  if Articulo <> '' then
    FBoard.FilterByArticulo(Articulo)
  else if CentreId >= 0 then
    FBoard.FilterByCentre(CentreId)
  else if Prioridad >= 0 then
    FBoard.FilterByPrioridad(Prioridad)
  else
    FBoard.ClearFilter;
end;

procedure TVistaKanbanForm.cbCentroChange(Sender: TObject);
begin
  if FApplyingFilters then Exit;
  ApplyFilters;
end;

procedure TVistaKanbanForm.cbPrioridadChange(Sender: TObject);
begin
  if FApplyingFilters then Exit;
  ApplyFilters;
end;

procedure TVistaKanbanForm.edArticuloChange(Sender: TObject);
begin
  if FApplyingFilters then Exit;
  ApplyFilters;
end;

procedure TVistaKanbanForm.btnLimpiarClick(Sender: TObject);
begin
  FApplyingFilters := True;
  try
    cbCentro.ItemIndex := 0;
    cbPrioridad.ItemIndex := 0;
    edArticulo.Text := '';
  finally
    FApplyingFilters := False;
  end;
  ApplyFilters;
end;

procedure TVistaKanbanForm.btnNuevaColClick(Sender: TObject);
var
  S: string;
begin
  S := 'Nueva columna';
  if InputQuery('A'#241'adir columna', 'Nombre de la columna:', S) then
  begin
    if Trim(S) = '' then Exit;
    FBoard.AddColumn(S, $00F0F0F0);
    FBoard.RefreshBoard;
  end;
end;

procedure TVistaKanbanForm.btnRestaurarClick(Sender: TObject);
begin
  if MessageDlg('Restaurar columnas y orden por defecto? Se perder'#225 +
                ' la configuraci'#243'n personalizada.',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  FBoard.BeginLoadLayout;
  try
    FBoard.ClearColumns;
    FBoard.AddColumn('Pendiente',  $00F1F2F4, Ord(nePendiente));
    FBoard.AddColumn('En Curso',   $00F1F2F4, Ord(neEnCurso));
    FBoard.AddColumn('Bloqueado',  $00F1F2F4, Ord(neBloqueado));
    FBoard.AddColumn('Finalizado', $00F1F2F4, Ord(neFinalizado));
  finally
    FBoard.EndLoadLayout;
  end;
  FBoard.RefreshBoard;
  FLayoutDirty := True;
end;

{ ========================================================= }
{               Carga del Backlog (BD)                       }
{ ========================================================= }

procedure TVistaKanbanForm.LoadBacklogFromDB;
const
  MAX_CARDS = 50;
var
  Q: TADOQuery;
  Cards: TArray<TKanbanBacklogCard>;
  Count, Total: Integer;
  Card: TKanbanBacklogCard;
  NextSyntheticId: Integer;
begin
  if FBoard = nil then Exit;
  if not Assigned(DMPlanner) or not DMPlanner.IsConnected then Exit;

  SetLength(Cards, 0);
  Count := 0;
  Total := 0;
  NextSyntheticId := -1;   // ids sint'eticos negativos, decrecientes

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;

    // Total para el badge "y N m'as"
    Q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM FS_PL_vw_Backlog ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa);
    Q.Open;
    if not Q.Eof then
      Total := Q.FieldByName('N').AsInteger;
    Q.Close;

    // Top N por compromiso/prioridad
    Q.SQL.Text :=
      'SELECT TOP ' + IntToStr(MAX_CARDS) + ' ' +
      '  RawId, TipoOrigen, CodigoDocumento, CodigoArticulo, ' +
      '  DescripcionArticulo, Cantidad, UnidadMedida, NombreCliente, ' +
      '  FechaCompromiso, Prioridad, HorasEstimadas, CentroPreferente ' +
      'FROM FS_PL_vw_Backlog ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) + ' ' +
      'ORDER BY FechaCompromiso, Prioridad DESC';
    Q.Open;

    SetLength(Cards, MAX_CARDS);
    while not Q.Eof do
    begin
      FillChar(Card, SizeOf(Card), 0);
      Card.SyntheticId := NextSyntheticId;
      Dec(NextSyntheticId);
      Card.RawId           := Q.FieldByName('RawId').AsLargeInt;
      Card.TipoOrigen      := Q.FieldByName('TipoOrigen').AsString;
      Card.CodigoDocumento := Q.FieldByName('CodigoDocumento').AsString;
      Card.CodigoArticulo  := Q.FieldByName('CodigoArticulo').AsString;
      Card.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      if not Q.FieldByName('Cantidad').IsNull then
        Card.Cantidad := Q.FieldByName('Cantidad').AsFloat;
      Card.UnidadMedida    := Q.FieldByName('UnidadMedida').AsString;
      Card.NombreCliente   := Q.FieldByName('NombreCliente').AsString;
      if not Q.FieldByName('FechaCompromiso').IsNull then
        Card.FechaCompromiso := Q.FieldByName('FechaCompromiso').AsDateTime;
      if not Q.FieldByName('Prioridad').IsNull then
        Card.Prioridad := Q.FieldByName('Prioridad').AsInteger;
      if not Q.FieldByName('HorasEstimadas').IsNull then
        Card.HorasEstimadas := Q.FieldByName('HorasEstimadas').AsFloat;
      Card.CentroPreferente := Q.FieldByName('CentroPreferente').AsString;

      Cards[Count] := Card;
      Inc(Count);
      Q.Next;
    end;
    SetLength(Cards, Count);
  finally
    Q.Free;
  end;

  FBoard.SetBacklogCards(Cards, Total);
end;

{ ========================================================= }
{               Layout change tracking                       }
{ ========================================================= }

procedure TVistaKanbanForm.OnBoardLayoutChanged(Sender: TObject);
begin
  FLayoutDirty := True;
end;

procedure TVistaKanbanForm.OnBacklogMoreClick(Sender: TObject);
begin
  // Cerrar Kanban y abrir Backlog
  Close;
  uBacklog.ShowBacklog;
end;

procedure TVistaKanbanForm.OnBoardCardMoved(Sender: TObject;
  const DataId: Integer; const OldState, NewState: TNodoEstado);
begin
  if Assigned(FOnPlanModified) then
    FOnPlanModified(TArray<Integer>.Create(DataId));
end;

{ ========================================================= }
{               Serialización JSON                           }
{ ========================================================= }

function TVistaKanbanForm.SerializeLayout: string;
var
  Root, ColObj, OrderObj, AssignObj: TJSONObject;
  ColsArr, OrdersArr, AssignsArr: TJSONArray;
  Cols: TArray<TKanbanColumnDef>;
  Orders, Assigns: TArray<TPair<Integer, Integer>>;
  I: Integer;
begin
  Cols := FBoard.GetColumnDefs;
  Orders := FBoard.GetCardOrders;
  Assigns := FBoard.GetCardColAssigns;

  Root := TJSONObject.Create;
  try
    Root.AddPair('Version', TJSONNumber.Create(1));

    ColsArr := TJSONArray.Create;
    for I := 0 to High(Cols) do
    begin
      // No persistir la columna Backlog (es din'amica)
      if Cols[I].MappedEstado = -2 then Continue;
      ColObj := TJSONObject.Create;
      ColObj.AddPair('Id',           TJSONNumber.Create(Cols[I].Id));
      ColObj.AddPair('Caption',      Cols[I].Caption);
      ColObj.AddPair('Color',        TJSONNumber.Create(Cols[I].Color));
      ColObj.AddPair('MappedEstado', TJSONNumber.Create(Cols[I].MappedEstado));
      ColObj.AddPair('Order',        TJSONNumber.Create(Cols[I].Order));
      ColsArr.AddElement(ColObj);
    end;
    Root.AddPair('Columns', ColsArr);

    OrdersArr := TJSONArray.Create;
    for I := 0 to High(Orders) do
    begin
      if Orders[I].Key < 0 then Continue;   // skip cards de Backlog
      OrderObj := TJSONObject.Create;
      OrderObj.AddPair('DataId',    TJSONNumber.Create(Orders[I].Key));
      OrderObj.AddPair('SortIndex', TJSONNumber.Create(Orders[I].Value));
      OrdersArr.AddElement(OrderObj);
    end;
    Root.AddPair('CardOrders', OrdersArr);

    AssignsArr := TJSONArray.Create;
    for I := 0 to High(Assigns) do
    begin
      if Assigns[I].Key < 0 then Continue;  // skip cards de Backlog
      AssignObj := TJSONObject.Create;
      AssignObj.AddPair('DataId', TJSONNumber.Create(Assigns[I].Key));
      AssignObj.AddPair('ColId',  TJSONNumber.Create(Assigns[I].Value));
      AssignsArr.AddElement(AssignObj);
    end;
    Root.AddPair('CardAssigns', AssignsArr);

    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

procedure TVistaKanbanForm.DeserializeLayout(const AJson: string);
var
  Root: TJSONObject;
  ColsArr, OrdersArr, AssignsArr: TJSONArray;
  ColObj: TJSONObject;
  V: TJSONValue;
  I, Id, Color, MappedEstado, Order, DataId, SortIndex, ColId: Integer;
  Caption: string;
begin
  V := TJSONObject.ParseJSONValue(AJson);
  if not (V is TJSONObject) then
  begin
    if V <> nil then V.Free;
    Exit;
  end;
  Root := TJSONObject(V);
  try
    FBoard.BeginLoadLayout;
    try
      FBoard.ClearColumns;

      ColsArr := Root.GetValue<TJSONArray>('Columns');
      if ColsArr <> nil then
      begin
        for I := 0 to ColsArr.Count - 1 do
        begin
          ColObj := ColsArr.Items[I] as TJSONObject;
          Id           := ColObj.GetValue<Integer>('Id');
          Caption      := ColObj.GetValue<string>('Caption');
          Color        := ColObj.GetValue<Integer>('Color');
          MappedEstado := ColObj.GetValue<Integer>('MappedEstado');
          Order        := ColObj.GetValue<Integer>('Order');
          FBoard.AddColumn(Id, Caption, Color, MappedEstado, Order);
        end;
      end;

      OrdersArr := Root.GetValue<TJSONArray>('CardOrders');
      if OrdersArr <> nil then
      begin
        for I := 0 to OrdersArr.Count - 1 do
        begin
          ColObj := OrdersArr.Items[I] as TJSONObject;
          DataId    := ColObj.GetValue<Integer>('DataId');
          SortIndex := ColObj.GetValue<Integer>('SortIndex');
          FBoard.SetCardOrder(DataId, SortIndex);
        end;
      end;

      AssignsArr := Root.GetValue<TJSONArray>('CardAssigns');
      if AssignsArr <> nil then
      begin
        for I := 0 to AssignsArr.Count - 1 do
        begin
          ColObj := AssignsArr.Items[I] as TJSONObject;
          DataId := ColObj.GetValue<Integer>('DataId');
          ColId  := ColObj.GetValue<Integer>('ColId');
          FBoard.SetCardColAssign(DataId, ColId);
        end;
      end;
    finally
      FBoard.EndLoadLayout;
    end;
    FBoard.RefreshBoard;
  finally
    Root.Free;
  end;
end;

{ ========================================================= }
{               Carga / Guardado UserPrefs                   }
{ ========================================================= }

procedure TVistaKanbanForm.LoadLayoutFromPrefs;
var
  S: string;
begin
  S := GetPref(PREF_MODULE, PREF_KEY_LAYOUT, '');
  if Trim(S) = '' then Exit;  // sin pref -> mantener defaults del board
  try
    DeserializeLayout(S);
    FLayoutDirty := False;
  except
    // JSON corrupto: ignorar y mantener defaults
  end;
end;

procedure TVistaKanbanForm.SaveLayoutToPrefs;
begin
  SetPref(PREF_MODULE, PREF_KEY_LAYOUT, SerializeLayout);
  FLayoutDirty := False;
end;

end.
