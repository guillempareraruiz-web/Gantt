unit uNodesRepo;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Graphics,
  Data.Win.ADODB, Data.DB,
  uGanttTypes, uNodeDataRepo;

type
  TNodesRepo = class
  private
    FConnection: TADOConnection;
    FNodes: TArray<TNode>;
  public
    constructor Create(AConnection: TADOConnection);
    procedure Clear;
    procedure LoadFromDB(ACodigoEmpresa: SmallInt; AProjectId: Integer;
      AFillNodeDataRepo: TNodeDataRepo);
    function GetAll: TArray<TNode>;
    function Count: Integer;
  end;

implementation

const
  // Colores por defecto de los nodos (azul cal).
  // Fill   = BGR $00E8B880 (RGB 128,184,232)
  // Border = BGR $00AA6428 (RGB  40,100,170)
  DEFAULT_NODE_FILL_COLOR   : TColor = TColor($00E8B880);
  DEFAULT_NODE_BORDER_COLOR : TColor = TColor($00AA6428);

constructor TNodesRepo.Create(AConnection: TADOConnection);
begin
  inherited Create;
  FConnection := AConnection;
  SetLength(FNodes, 0);
end;

procedure TNodesRepo.Clear;
begin
  SetLength(FNodes, 0);
end;

function TNodesRepo.Count: Integer;
begin
  Result := Length(FNodes);
end;

function TNodesRepo.GetAll: TArray<TNode>;
begin
  Result := FNodes;
end;

procedure TNodesRepo.LoadFromDB(ACodigoEmpresa: SmallInt; AProjectId: Integer;
  AFillNodeDataRepo: TNodeDataRepo);
var
  Q: TADOQuery;
  I: Integer;
  N: TNode;
  D: TNodeData;
begin
  Clear;
  if AFillNodeDataRepo <> nil then
    AFillNodeDataRepo.Clear;

  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT n.NodeId, n.CenterId, n.FechaInicio, n.FechaFin, n.DuracionMin, ' +
      '  ISNULL(n.Caption, '''') AS Caption, ' +
      '  ISNULL(n.ColorFondo, 0) AS ColorFondo, ' +
      '  ISNULL(n.ColorBorde, 0) AS ColorBorde, ' +
      '  n.Visible, n.Habilitado, ' +
      '  ISNULL(nd.Operacion, '''') AS Operacion, ' +
      '  ISNULL(nd.NumeroPedido, 0) AS NumeroPedido, ' +
      '  ISNULL(nd.SeriePedido, '''') AS SeriePedido, ' +
      '  ISNULL(nd.NumeroOF, 0) AS NumeroOF, ' +
      '  ISNULL(nd.SerieOF, '''') AS SerieOF, ' +
      '  ISNULL(nd.NumeroTrabajo, '''') AS NumeroTrabajo, ' +
      '  ISNULL(nd.CodigoCliente, '''') AS CodigoCliente, ' +
      '  ISNULL(nd.CodigoArticulo, '''') AS CodigoArticulo, ' +
      '  ISNULL(nd.DescripcionArticulo, '''') AS DescripcionArticulo, ' +
      '  ISNULL(nd.UnidadesFabricadas, 0) AS UnidadesFabricadas, ' +
      '  ISNULL(nd.UnidadesAFabricar, 0) AS UnidadesAFabricar, ' +
      '  ISNULL(nd.TiempoUnidadFabSecs, 0) AS TiempoUnidadFabSecs, ' +
      '  ISNULL(nd.DuracionMin, 0) AS DurMin, ' +
      '  ISNULL(nd.DuracionMinOriginal, 0) AS DurMinOrig, ' +
      '  ISNULL(nd.OperariosNecesarios, 0) AS OperariosNecesarios, ' +
      '  ISNULL(nd.OperariosAsignados, 0) AS OperariosAsignados, ' +
      '  ISNULL(nd.Estado, 0) AS Estado, ' +
      '  ISNULL(nd.Tipo, 0) AS Tipo, ' +
      '  ISNULL(nd.Prioridad, 0) AS Prioridad, ' +
      '  ISNULL(nd.ColorFondoOp, 0) AS ColorFondoOp, ' +
      '  ISNULL(nd.ColorBordeOp, 0) AS ColorBordeOp, ' +
      '  ISNULL(nd.LibreMovimiento, 0) AS LibreMovimiento, ' +
      '  ISNULL(nd.Stock, 0) AS Stock, ' +
      '  ISNULL(nd.PorcentajeDependencia, 0) AS PorcentajeDependencia, ' +
      // Campos del modelo unificado (V016) y cadena de padres (V018)
      '  ISNULL(nd.RawItemClaveERP, '''') AS RawItemClaveERP, ' +
      '  ISNULL(nd.RawItemTipoOrigen, '''') AS RawItemTipoOrigen, ' +
      '  ISNULL(gp.Nivel1ClaveERP, '''') AS Nivel1ClaveERP, ' +
      '  ISNULL(gp.Nivel1Caption, '''') AS Nivel1Caption, ' +
      '  ISNULL(gp.Nivel2ClaveERP, '''') AS Nivel2ClaveERP, ' +
      '  ISNULL(gp.Nivel2Caption, '''') AS Nivel2Caption ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'LEFT JOIN FS_PL_vw_NodeGroupParent gp ON gp.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND gp.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CodigoEmpresa AND n.ProjectId = :ProjectId ' +
      'ORDER BY n.NodeId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := ACodigoEmpresa;
    Q.Parameters.ParamByName('ProjectId').Value := AProjectId;
    Q.Open;

    SetLength(FNodes, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      // ── TNode ──
      N.Id := Q.FieldByName('NodeId').AsInteger;
      N.DataId := N.Id; // usamos el mismo ID para el lookup a NodeData

      if Q.FieldByName('CenterId').IsNull then
        N.CentreId := -1
      else
        N.CentreId := Q.FieldByName('CenterId').AsInteger;

      if Q.FieldByName('FechaInicio').IsNull then
        N.StartTime := 0
      else
        N.StartTime := Q.FieldByName('FechaInicio').AsDateTime;

      if Q.FieldByName('FechaFin').IsNull then
        N.EndTime := 0
      else
        N.EndTime := Q.FieldByName('FechaFin').AsDateTime;

      N.DurationMin := Q.FieldByName('DuracionMin').AsFloat;
      N.Caption := Q.FieldByName('Caption').AsString;
      if N.Caption = '' then
        N.Caption := Q.FieldByName('Operacion').AsString;

      N.FillColor := TColor(Q.FieldByName('ColorFondo').AsInteger);
      if N.FillColor = clBlack then
        N.FillColor := DEFAULT_NODE_FILL_COLOR;
      N.BorderColor := TColor(Q.FieldByName('ColorBorde').AsInteger);
      if N.BorderColor = clBlack then
        N.BorderColor := DEFAULT_NODE_BORDER_COLOR;
      N.HoverColor := N.FillColor;
      N.Visible := Q.FieldByName('Visible').AsBoolean;
      N.Enabled := Q.FieldByName('Habilitado').AsBoolean;

      FNodes[I] := N;

      // ── TNodeData ──
      if AFillNodeDataRepo <> nil then
      begin
        FillChar(D, SizeOf(D), 0);
        D.DataId := N.Id;
        D.Operacion := Q.FieldByName('Operacion').AsString;
        D.NumeroPedido := Q.FieldByName('NumeroPedido').AsInteger;
        D.SeriePedido := Q.FieldByName('SeriePedido').AsString;
        D.NumeroOrdenFabricacion := Q.FieldByName('NumeroOF').AsInteger;
        D.SerieFabricacion := Q.FieldByName('SerieOF').AsString;
        D.NumeroTrabajo := Q.FieldByName('NumeroTrabajo').AsString;
        D.CodigoCliente := Q.FieldByName('CodigoCliente').AsString;
        D.CodigoArticulo := Q.FieldByName('CodigoArticulo').AsString;
        D.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
        D.UnidadesFabricadas := Q.FieldByName('UnidadesFabricadas').AsFloat;
        D.UnidadesAFabricar := Q.FieldByName('UnidadesAFabricar').AsFloat;
        D.TiempoUnidadFabSecs := Q.FieldByName('TiempoUnidadFabSecs').AsFloat;
        D.DurationMin := Q.FieldByName('DurMin').AsFloat;
        D.DurationMinOriginal := Q.FieldByName('DurMinOrig').AsFloat;
        D.OperariosNecesarios := Q.FieldByName('OperariosNecesarios').AsInteger;
        D.OperariosAsignados := Q.FieldByName('OperariosAsignados').AsInteger;
        D.Estado := TNodoEstado(Q.FieldByName('Estado').AsInteger);
        D.Tipo := TNodoTipo(Q.FieldByName('Tipo').AsInteger);
        D.Prioridad := Q.FieldByName('Prioridad').AsInteger;
        D.bkColorOp := TColor(Q.FieldByName('ColorFondoOp').AsInteger);
        if D.bkColorOp = clBlack then
          D.bkColorOp := DEFAULT_NODE_FILL_COLOR;
        D.borderColorOp := TColor(Q.FieldByName('ColorBordeOp').AsInteger);
        if D.borderColorOp = clBlack then
          D.borderColorOp := DEFAULT_NODE_BORDER_COLOR;
        D.LibreMoviment := Q.FieldByName('LibreMovimiento').AsBoolean;
        D.Stock := Q.FieldByName('Stock').AsFloat;
        D.PorcentajeDependencia := Q.FieldByName('PorcentajeDependencia').AsFloat;
        // Link modelo unificado Raw_Item (V016+) + cadena de padres (V018+)
        if Q.FindField('RawItemClaveERP') <> nil then
          D.RawItemClaveERP := Q.FieldByName('RawItemClaveERP').AsString;
        if Q.FindField('RawItemTipoOrigen') <> nil then
          D.RawItemTipoOrigen := Q.FieldByName('RawItemTipoOrigen').AsString;
        if Q.FindField('Nivel1ClaveERP') <> nil then
          D.Nivel1ClaveERP := Q.FieldByName('Nivel1ClaveERP').AsString;
        if Q.FindField('Nivel1Caption') <> nil then
          D.Nivel1Caption := Q.FieldByName('Nivel1Caption').AsString;
        if Q.FindField('Nivel2ClaveERP') <> nil then
          D.Nivel2ClaveERP := Q.FieldByName('Nivel2ClaveERP').AsString;
        if Q.FindField('Nivel2Caption') <> nil then
          D.Nivel2Caption := Q.FieldByName('Nivel2Caption').AsString;
        AFillNodeDataRepo.AddOrUpdate(D);
      end;

      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.
