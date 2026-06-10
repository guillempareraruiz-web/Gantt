unit uOFViewer;

// ============================================================================
// Visor de OF (OF Viewer): muestra la jerarquia completa de una Orden de
// Fabricacion (OF -> OTs -> OPs) en un arbol (TcxTreeList) a la izquierda y,
// al seleccionar un nodo, todos sus campos/valores en un VerticalGrid a la
// derecha (a modo de inspector OF/OT/OP).
//
// Fuente de datos: FS_PL_Raw_Item (lo SINCRONIZADO), coherente con el grid del
// Backlog. Se abre desde el Backlog (doble-clic en fila o boton "Ver OF").
// Recibe el RawItemId de la fila pulsada, sube hasta la OF raiz y carga toda
// su descendencia con una query recursiva.
//
// Solo lectura. Conexion del Planner (DMPlanner). Dialogo modal con ayuda en
// el caption (THelpViewer.InstallHelp).
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls,
  Data.Win.ADODB, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxInplaceContainer, cxVGrid,
  cxTL, cxTLData, cxTextEdit, dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue, cxFilter, dxScrollbarAnnotations, cxTLdxBarBuiltInMenu;

type
  // Un item de la jerarquia leido de FS_PL_Raw_Item. Guardamos todos los campos
  // (Name=Value) para el detalle, y los basicos para el arbol.
  TOFViewerNode = class
  public
    RawItemId: Int64;
    ParentRawItemId: Int64;
    Nivel: Integer;
    TipoOrigen: string;
    Fields: TStringList;   // Name=Value en orden de la query
    constructor Create;
    destructor Destroy; override;
  end;

  TfrmOFViewer = class(TForm)
    pnlClient: TPanel;
    tlOF: TcxTreeList;
    colNivel: TcxTreeListColumn;
    colCodigo: TcxTreeListColumn;
    colDescripcion: TcxTreeListColumn;
    colEstado: TcxTreeListColumn;
    splMain: TSplitter;
    pnlDetalle: TPanel;
    vgDetalle: TcxVerticalGrid;
    pnlTop: TPanel;
    lblDetalle: TLabel;
    Label1: TLabel;
    Panel1: TPanel;
    LblKPIS: TLabel;
    LblOF: TLabel;
    btnExpand: TLabel;
    Label3: TLabel;
    LblOTOP: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnExpandClick(Sender: TObject);
    procedure tlOFFocusedNodeChanged(Sender: TcxCustomTreeList;
      APrevFocusedNode, AFocusedNode: TcxTreeListNode);
  private
    FConn: TADOConnection;
    FEmpresa: SmallInt;
    FExpandido: Boolean;
    FNodos: TObjectList<TOFViewerNode>;
    function FindRootRawItemId(ARawItemId: Int64): Int64;
    procedure LoadHierarchy(ARootRawItemId: Int64);
    procedure BuildTree;
    procedure AddChildren(AParentNode: TcxTreeListNode; AParentRawId: Int64);
    procedure ShowDetail(AData: TOFViewerNode);
    procedure UpdateKpis(ARootData: TOFViewerNode);
    function NivelLabel(ANivel: Integer; const ATipoOrigen: string): string;
    function FieldCaption(const AName: string): string;
  public
    // Punto de entrada: ARawItemId de la fila del backlog pulsada (cualquier
    // nivel). Resuelve la OF raiz y carga toda la jerarquia.
    class procedure Execute(ARawItemId: Int64);
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uHelpViewer;

// Captions legibles para los campos del VerticalGrid (Name -> Caption). Lo que
// no este en el mapa se muestra con su nombre tal cual.
function BuildCaptionMap: TDictionary<string, string>;
begin
  Result := TDictionary<string, string>.Create;
  Result.Add('ClaveERP', 'Clave ERP');
  Result.Add('CodigoArticulo', 'Art'#237'culo');
  Result.Add('DescripcionArticulo', 'Descripci'#243'n art'#237'culo');
  Result.Add('Codigo', 'C'#243'digo');
  Result.Add('Nombre', 'Nombre');
  Result.Add('Descripcion', 'Descripci'#243'n');
  Result.Add('Cantidad', 'Cantidad');
  Result.Add('UnidadMedida', 'U.M.');
  Result.Add('CodigoCliente', 'C'#243'd. cliente');
  Result.Add('NombreCliente', 'Cliente');
  Result.Add('CodigoProyecto', 'Proyecto');
  Result.Add('NumeroDoc', 'N'#250'mero doc.');
  Result.Add('SerieDoc', 'Serie doc.');
  Result.Add('LineaDoc', 'L'#237'nea doc.');
  Result.Add('Orden', 'Orden op.');
  Result.Add('FechaCompromiso', 'F. Compromiso');
  Result.Add('FechaNecesaria', 'F. Necesaria');
  Result.Add('FechaInicioPrev', 'Inicio previsto');
  Result.Add('FechaFinPrev', 'Fin previsto');
  Result.Add('FechaLanzamiento', 'Lanzamiento');
  Result.Add('FechaPedido', 'F. Pedido');
  Result.Add('Prioridad', 'Prioridad');
  Result.Add('CentroPreferente', 'Centro pref.');
  Result.Add('HorasEstimadas', 'Horas est.');
  Result.Add('EstadoERP', 'Estado');
  Result.Add('Observaciones', 'Observaciones');
  Result.Add('OpTiempoPreparacion', 'T. Preparaci'#243'n');
  Result.Add('OpTiempoFabricacion', 'T. Fabricaci'#243'n');
  Result.Add('OpUnidadesHora', 'Uds/hora');
  Result.Add('OpCosteHoraMaquina', 'Coste/h m'#225'quina');
  Result.Add('OpCosteHoraManoObra', 'Coste/h mano obra');
  Result.Add('OpUnidadesFabricadas', 'Uds fabricadas');
  Result.Add('OpFechaInicioReal', 'Inicio real');
  Result.Add('OpFechaFinalReal', 'Fin real');
  Result.Add('OpOperacionExterna', 'Operaci'#243'n externa');
  Result.Add('OpCodigoProveedor', 'Proveedor');
  Result.Add('OpSeccionFabrica', 'Secci'#243'n');
  Result.Add('OpStatusPlanificado', 'Planificado');
  Result.Add('OpObservaciones', 'Obs. operaci'#243'n');
  Result.Add('OpPctParaSigOperacion', '% para sig. op.');
  Result.Add('OpPctDedicacionOperario', '% dedicaci'#243'n operario');
end;

var
  GCaptionMap: TDictionary<string, string>;

{ TOFViewerNode }

constructor TOFViewerNode.Create;
begin
  inherited;
  Fields := TStringList.Create;
end;

destructor TOFViewerNode.Destroy;
begin
  Fields.Free;
  inherited;
end;

{ TfrmOFViewer }

class procedure TfrmOFViewer.Execute(ARawItemId: Int64);
var
  F: TfrmOFViewer;
  Root: Int64;
begin
  F := TfrmOFViewer.Create(Application);
  try
    Root := F.FindRootRawItemId(ARawItemId);
    if Root <= 0 then
    begin
      MessageBox(0, 'No se ha podido localizar la OF de esta fila.',
        'Visor de OF', MB_ICONWARNING or MB_OK);
      Exit;
    end;
    F.LoadHierarchy(Root);
    F.BuildTree;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmOFViewer.FormCreate(Sender: TObject);
var
  StHeader: TcxStyle;
begin
  FConn := DMPlanner.ADOConnection;
  FEmpresa := DMPlanner.CodigoEmpresa;
  FNodos := TObjectList<TOFViewerNode>.Create(True);
  THelpViewer.InstallHelp(Self, 'uOFViewer', 'Visor de OF');

  // Columna izquierda (cabeceras de fila) del VerticalGrid con fondo gris claro.
  StHeader := TcxStyle.Create(Self);
  StHeader.Color := $00F2F2F2;   // gris claro
  vgDetalle.Styles.Header := StHeader;
end;

procedure TfrmOFViewer.FormDestroy(Sender: TObject);
begin
  FNodos.Free;
end;

procedure TfrmOFViewer.btnCerrarClick(Sender: TObject);
begin

end;

// Compactar/Expandir todo el arbol. Toggle segun el estado actual.
procedure TfrmOFViewer.btnExpandClick(Sender: TObject);
begin
  if FExpandido then
    tlOF.FullCollapse
  else
    tlOF.FullExpand;
  FExpandido := not FExpandido;
end;

// Sube por ParentRawItemId hasta la raiz (ParentRawItemId NULL = Nivel 1).
function TfrmOFViewer.FindRootRawItemId(ARawItemId: Int64): Int64;
var
  Q: TADOQuery;
  Cur, Parent: Int64;
  Guard: Integer;
begin
  Result := 0;
  Cur := ARawItemId;
  Guard := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    while (Cur > 0) and (Guard < 10) do
    begin
      Q.Close;
      Q.SQL.Text :=
        'SELECT ParentRawItemId FROM FS_PL_Raw_Item ' +
        'WHERE CodigoEmpresa = :Emp AND RawItemId = :Rid';
      Q.Parameters.ParamByName('Emp').Value := FEmpresa;
      Q.Parameters.ParamByName('Rid').Value := Cur;
      Q.Open;
      if Q.Eof then Break;
      if Q.FieldByName('ParentRawItemId').IsNull then
      begin
        Result := Cur;   // sin padre = raiz
        Break;
      end;
      Parent := Q.FieldByName('ParentRawItemId').AsLargeInt;
      if Parent = Cur then Break;   // proteccion ante datos inconsistentes
      Cur := Parent;
      Inc(Guard);
    end;
  finally
    Q.Free;
  end;
end;

// Carga la OF raiz + toda su descendencia (OTs y OPs) en FNodos via CTE recursivo.
procedure TfrmOFViewer.LoadHierarchy(ARootRawItemId: Int64);
var
  Q: TADOQuery;
  D: TOFViewerNode;
  I: Integer;
  FldName: string;
begin
  FNodos.Clear;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'WITH Tree AS ( ' +
      '  SELECT ri.* FROM FS_PL_Raw_Item ri ' +
      '   WHERE ri.CodigoEmpresa = :Emp AND ri.RawItemId = :Root ' +
      '  UNION ALL ' +
      '  SELECT c.* FROM FS_PL_Raw_Item c ' +
      '   INNER JOIN Tree t ON c.CodigoEmpresa = t.CodigoEmpresa ' +
      '                    AND c.ParentRawItemId = t.RawItemId ' +
      '   WHERE c.Activo = 1 ' +
      ') ' +
      'SELECT * FROM Tree ORDER BY Nivel, Orden, RawItemId';
    Q.Parameters.ParamByName('Emp').Value := FEmpresa;
    Q.Parameters.ParamByName('Root').Value := ARootRawItemId;
    Q.Open;
    while not Q.Eof do
    begin
      D := TOFViewerNode.Create;
      D.RawItemId := Q.FieldByName('RawItemId').AsLargeInt;
      if Q.FieldByName('ParentRawItemId').IsNull then
        D.ParentRawItemId := 0
      else
        D.ParentRawItemId := Q.FieldByName('ParentRawItemId').AsLargeInt;
      D.Nivel := Q.FieldByName('Nivel').AsInteger;
      D.TipoOrigen := Q.FieldByName('TipoOrigen').AsString;
      for I := 0 to Q.FieldCount - 1 do
      begin
        FldName := Q.Fields[I].FieldName;
        if Q.Fields[I].IsNull then
          D.Fields.Values[FldName] := ''
        else
          D.Fields.Values[FldName] := Q.Fields[I].AsString;
      end;
      FNodos.Add(D);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TfrmOFViewer.NivelLabel(ANivel: Integer;
  const ATipoOrigen: string): string;
begin
  if Trim(ATipoOrigen) = 'OF' then
    case ANivel of
      1: Result := 'OF';
      2: Result := 'OT';
      3: Result := 'OP';
    else Result := 'N' + IntToStr(ANivel);
    end
  else
    Result := 'N' + IntToStr(ANivel);
end;

function TfrmOFViewer.FieldCaption(const AName: string): string;
begin
  if not GCaptionMap.TryGetValue(AName, Result) then
    Result := AName;
end;

procedure TfrmOFViewer.BuildTree;
var
  RootData: TOFViewerNode;
  RootNode: TcxTreeListNode;
  D: TOFViewerNode;
begin
  tlOF.Clear;
  tlOF.BeginUpdate;
  try
    RootData := nil;
    for D in FNodos do
      if D.ParentRawItemId = 0 then
      begin
        RootData := D;
        Break;
      end;
    if RootData = nil then Exit;

    RootNode := tlOF.Add(nil, RootData);
    RootNode.Texts[colNivel.ItemIndex]       := NivelLabel(RootData.Nivel, RootData.TipoOrigen);
    RootNode.Texts[colCodigo.ItemIndex]      := RootData.Fields.Values['ClaveERP'];
    RootNode.Texts[colDescripcion.ItemIndex] := RootData.Fields.Values['DescripcionArticulo'];
    RootNode.Texts[colEstado.ItemIndex]      := RootData.Fields.Values['EstadoERP'];

    AddChildren(RootNode, RootData.RawItemId);
    tlOF.FullExpand;
    FExpandido := True;
  finally
    tlOF.EndUpdate;
  end;
  UpdateKpis(RootData);
  if tlOF.Root.Count > 0 then
    tlOF.Root.Items[0].Focused := True;
end;

// Rellena la cabecera de KPIs: LblOF con SerieOF.NumeroOF de la OF raiz y
// LblOTOP con el conteo de OF/OT/OP de toda la jerarquia cargada en FNodos.
procedure TfrmOFViewer.UpdateKpis(ARootData: TOFViewerNode);
var
  D: TOFViewerNode;
  NumOF, NumOT, NumOP: Integer;
  Serie, Numero: string;

  function Plural(N: Integer; const Sing, Plur: string): string;
  begin
    if N = 1 then Result := Sing else Result := Plur;
  end;

begin
  NumOF := 0; NumOT := 0; NumOP := 0;
  for D in FNodos do
    case D.Nivel of
      1: Inc(NumOF);
      2: Inc(NumOT);
      3: Inc(NumOP);
    end;

  LblOTOP.Caption := Format('%d %s   %d %s   %d %s',
    [NumOF, Plural(NumOF, 'Orden de fabricaci'#243'n', 'Ordenes de fabricaci'#243'n'),
     NumOT, Plural(NumOT, 'Orden de trabajo',        'Ordenes de trabajo'),
     NumOP, Plural(NumOP, 'Operaci'#243'n',              'Operaciones')]);

  // LblOF: SerieOF.NumeroOF de la OF raiz (sin ejercicio: la tabla no lo expone).
  Serie  := Trim(ARootData.Fields.Values['SerieDoc']);
  Numero := Trim(ARootData.Fields.Values['NumeroDoc']);
  if (Serie <> '') and (Numero <> '') then
    LblOF.Caption := Serie + '.' + Numero
  else if Numero <> '' then
    LblOF.Caption := Numero
  else
    LblOF.Caption := Trim(ARootData.Fields.Values['ClaveERP']);
end;

procedure TfrmOFViewer.AddChildren(AParentNode: TcxTreeListNode;
  AParentRawId: Int64);
var
  D: TOFViewerNode;
  Node: TcxTreeListNode;
  Desc, Cod: string;
begin
  for D in FNodos do
    if D.ParentRawItemId = AParentRawId then
    begin
      Node := tlOF.AddChild(AParentNode, D);
      // Codigo: el propio Codigo (op/ot); si vacio, la ClaveERP.
      Cod := D.Fields.Values['Codigo'];
      if Trim(Cod) = '' then
        Cod := D.Fields.Values['ClaveERP'];
      // Descripcion: Nombre o, si vacio, descripcion del articulo.
      Desc := D.Fields.Values['Nombre'];
      if Trim(Desc) = '' then
        Desc := D.Fields.Values['DescripcionArticulo'];
      Node.Texts[colNivel.ItemIndex]       := NivelLabel(D.Nivel, D.TipoOrigen);
      Node.Texts[colCodigo.ItemIndex]      := Cod;
      Node.Texts[colDescripcion.ItemIndex] := Desc;
      Node.Texts[colEstado.ItemIndex]      := D.Fields.Values['EstadoERP'];
      AddChildren(Node, D.RawItemId);
    end;
end;

procedure TfrmOFViewer.tlOFFocusedNodeChanged(Sender: TcxCustomTreeList;
  APrevFocusedNode, AFocusedNode: TcxTreeListNode);
begin
  if (AFocusedNode <> nil) and (AFocusedNode.Data <> nil) then
    ShowDetail(TOFViewerNode(AFocusedNode.Data))
  else
    vgDetalle.ClearRows;
end;

// Muestra en el VerticalGrid todos los campos con valor del item seleccionado.
// Se omiten los vacios/NULL para no ensuciar (p.ej. una OF no tiene campos Op*).
procedure TfrmOFViewer.ShowDetail(AData: TOFViewerNode);
var
  I: Integer;
  Row: TcxEditorRow;
  FldName, FldVal: string;
begin
  vgDetalle.BeginUpdate;
  try
    vgDetalle.ClearRows;
    lblDetalle.Caption := 'Detalle: ' +
      NivelLabel(AData.Nivel, AData.TipoOrigen) + '  ' +
      AData.Fields.Values['ClaveERP'];
    for I := 0 to AData.Fields.Count - 1 do
    begin
      FldName := AData.Fields.Names[I];
      FldVal  := AData.Fields.ValueFromIndex[I];
      if Trim(FldVal) = '' then Continue;
      // Campos internos que no aportan al usuario.
      if (FldName = 'CodigoEmpresa') or (FldName = 'Activo') or
         (FldName = 'LastErpHash') then Continue;
      Row := vgDetalle.Add(TcxEditorRow) as TcxEditorRow;
      Row.Properties.Caption := FieldCaption(FldName);
      Row.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
      (Row.Properties.EditProperties as TcxTextEditProperties).ReadOnly := True;
      Row.Properties.Value := FldVal;
    end;
  finally
    vgDetalle.EndUpdate;
  end;
end;

initialization
  GCaptionMap := BuildCaptionMap;

finalization
  GCaptionMap.Free;

end.
