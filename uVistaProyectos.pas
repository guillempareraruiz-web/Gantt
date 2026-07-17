unit uVistaProyectos;

{
  Modulo de PROYECTOS (planificacion estilo MS Project, paradigma TAREAS).

  Fase 1 (esqueleto, SOLO LECTURA): a la izquierda un grid WBS jerarquico
  (cxTreeList) con Nombre / Duracion / Inicio / Fin; a la derecha el Gantt de
  tareas (TGanttControlTareas), sincronizado fila a fila por scroll vertical.

  Muestra los datos existentes de un proyecto TAREAS (p.ej. el demo ProjectId 6)
  SIN edicion. La edicion (columnas in-place, indentar, dependencias) y el motor
  de fechas son fases posteriores.

  Se abre desde el Main (boton de toolbar) segun FS_PL_Project.PlanningParadigm.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxTL, cxTLData, cxTextEdit,
  cxInplaceContainer,
  dxSkinsCore, dxSkinsDefaultPainters,
  uGanttControl, uGanttControlTareas, uGanttTypes, uNodeDataRepo,
  uWbsTypes, uWbsRepo;

type
  TfrmVistaProyectos = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlLeft: TPanel;
    tlWbs: TcxTreeList;
    colNombre: TcxTreeListColumn;
    colDuracion: TcxTreeListColumn;
    colInicio: TcxTreeListColumn;
    colFin: TcxTreeListColumn;
    splMain: TSplitter;
    pnlRight: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FGantt: TGanttControlTareas;
    FProjectId: Integer;
    FTareas: TWbsTaskArray;
    FLinks: TWbsLinkArray;
    FNodeToTLNode: TDictionary<Integer, TcxTreeListNode>;
    FNodeDataRepo: TNodeDataRepo;   // NodeData del proyecto (el Gantt lo necesita)
    procedure CargarDatos;
    procedure ConstruirArbol;
    procedure ConstruirGantt;
    procedure AjustarZoomFit(const AIni, AFin: TDateTime);
    procedure GanttScrollYChanged(Sender: TObject; const AScrollY: Single);
    function RangoFechas(out AIni, AFin: TDateTime): Boolean;
  public
    // Carga y muestra el proyecto (paradigma TAREAS). El form se usa EMBEBIDO
    // en el Main (Parent := Form1, Align := alClient), como uVistaGantt.
    procedure Inicializar(AProjectId: Integer);
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.Math, Vcl.Dialogs, Data.Win.ADODB,
  uDMPlanner, uNodesRepo;

procedure TfrmVistaProyectos.Inicializar(AProjectId: Integer);
begin
  FProjectId := AProjectId;
  try
    CargarDatos;
    ConstruirArbol;
    ConstruirGantt;
  except
    on E: Exception do
      // Mostrar el error real (clase + mensaje) en vez de un Access Violation
      // ciego, para diagnosticar durante el desarrollo del modulo.
      Vcl.Dialogs.MessageDlg(
        'Error al construir la vista de proyectos:'#13#10#13#10 +
        E.ClassName + ': ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmVistaProyectos.FormCreate(Sender: TObject);
begin
  FNodeToTLNode := TDictionary<Integer, TcxTreeListNode>.Create;
  FNodeDataRepo := TNodeDataRepo.Create;

  // Control de Gantt de tareas a la derecha (creado en codigo, como en el resto
  // de vistas de Gantt del proyecto).
  FGantt := TGanttControlTareas.Create(Self);
  FGantt.Parent := pnlRight;
  FGantt.Align := alClient;
  FGantt.ShowHint := True;
  FGantt.OnScrollYChanged := GanttScrollYChanged;
end;

procedure TfrmVistaProyectos.GanttScrollYChanged(Sender: TObject;
  const AScrollY: Single);
begin
  // Fase 1: placeholder. La sincronia fina fila-a-fila grid<->Gantt es Fase 3.
end;

procedure TfrmVistaProyectos.FormDestroy(Sender: TObject);
begin
  FNodeToTLNode.Free;
  FNodeDataRepo.Free;
end;

procedure TfrmVistaProyectos.CargarDatos;
var
  Repo: TWbsRepo;
  Q: TADOQuery;
  Nombre: string;
begin
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  // Nombre del proyecto para el titulo del header.
  Nombre := '';
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT Nombre FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := FProjectId;
    Q.Open;
    if not Q.Eof then Nombre := Q.Fields[0].AsString;
  finally
    Q.Free;
  end;
  if Trim(Nombre) = '' then Nombre := 'Proyecto ' + IntToStr(FProjectId);
  lblTitulo.Caption := Nombre;

  Repo := TWbsRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    FTareas := Repo.LoadTareas(FProjectId);
    FLinks := Repo.LoadLinks(FProjectId);
  finally
    Repo.Free;
  end;
end;

procedure TfrmVistaProyectos.ConstruirArbol;
var
  I: Integer;
  T: TWbsTask;
  TLNode, TLParent: TcxTreeListNode;
begin
  tlWbs.BeginUpdate;
  try
    tlWbs.Clear;
    FNodeToTLNode.Clear;

    // FTareas ya viene en orden de arbol (padre antes que hijo), asi que al
    // llegar a un hijo su padre ya existe en el mapa.
    for I := 0 to High(FTareas) do
    begin
      T := FTareas[I];
      if (T.ParentTaskId <> 0) and
         FNodeToTLNode.TryGetValue(T.ParentTaskId, TLParent) then
        TLNode := tlWbs.AddChild(TLParent)
      else
        TLNode := tlWbs.Add;   // raiz

      TLNode.Texts[colNombre.ItemIndex]   := T.Caption;
      TLNode.Texts[colDuracion.ItemIndex] := FormatDias(T.DuracionMin);
      if T.FechaInicio > 0 then
        TLNode.Texts[colInicio.ItemIndex] := FormatDateTime('dd/mm/yyyy', T.FechaInicio);
      if T.FechaFin > 0 then
        TLNode.Texts[colFin.ItemIndex]    := FormatDateTime('dd/mm/yyyy', T.FechaFin);
      // Hito: marcar con rombo (#$25C6) en el nombre.
      if T.Kind = wtkHito then
        TLNode.Texts[colNombre.ItemIndex] := #$25C6' ' + T.Caption;

      FNodeToTLNode.AddOrSetValue(T.NodeId, TLNode);
    end;

    tlWbs.FullExpand;
  finally
    tlWbs.EndUpdate;
  end;
end;

function TfrmVistaProyectos.RangoFechas(out AIni, AFin: TDateTime): Boolean;
var
  I: Integer;
begin
  AIni := 0; AFin := 0;
  Result := False;
  for I := 0 to High(FTareas) do
  begin
    if FTareas[I].FechaInicio > 0 then
    begin
      if (AIni = 0) or (FTareas[I].FechaInicio < AIni) then AIni := FTareas[I].FechaInicio;
      Result := True;
    end;
    if FTareas[I].FechaFin > 0 then
      if (AFin = 0) or (FTareas[I].FechaFin > AFin) then AFin := FTareas[I].FechaFin;
  end;
  if Result and (AFin <= AIni) then AFin := AIni + 30;
end;

procedure TfrmVistaProyectos.ConstruirGantt;
var
  NodesRepo: TNodesRepo;
  Nodes: TArray<TNode>;
  Orden: TWbsRowInfoArray;
  I: Integer;
  Ini, Fin: TDateTime;
begin
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  // Cargar las tareas como TNode (son nodos de FS_PL_Node) reutilizando el
  // repo de nodos existente. Se rellena FNodeDataRepo con los NodeData del
  // proyecto: el Gantt lo necesita para resolver datos al pintar (si es nil,
  // TryGetById peta con Access Violation).
  FNodeDataRepo.Clear;
  NodesRepo := TNodesRepo.Create(DMPlanner.ADOConnection);
  try
    NodesRepo.LoadFromDB(DMPlanner.CodigoEmpresa, FProjectId, FNodeDataRepo);
    Nodes := NodesRepo.GetAll;
  finally
    NodesRepo.Free;
  end;

  // Imprescindible antes de SetData: sin repo de NodeData, el paint del Gantt
  // accede a un puntero nil.
  FGantt.SetNodeRepo(FNodeDataRepo);

  // Inyectar el orden WBS (una fila por tarea visible, respetando plegado).
  SetLength(Orden, Length(FTareas));
  for I := 0 to High(FTareas) do
  begin
    Orden[I].NodeId := FTareas[I].NodeId;
    Orden[I].Kind := FTareas[I].Kind;
    Orden[I].Nivel := FTareas[I].Nivel;
    Orden[I].Visible := True;   // Fase 1: todo visible (acordeon en Fase 3)
  end;
  FGantt.SetOrden(Orden);

  // Rango temporal del Gantt. Fallback a hoy si el proyecto no tiene fechas.
  if not RangoFechas(Ini, Fin) then
  begin
    Ini := Date;
    Fin := Date + 30;
  end;
  FGantt.SetTimeRange(DateOf(Ini) - 2, DateOf(Fin) + 2);
  FGantt.SetData(nil, Nodes, DateOf(Ini) - 2);
  // Zoom-to-fit: sin esto el zoom por defecto (2 px/min) hace que el rango
  // completo del proyecto quede muy lejos a la derecha y no se vea ninguna
  // barra. Ajustamos px/min para que el rango [Ini-2, Fin+2] quepa en el ancho.
  AjustarZoomFit(DateOf(Ini) - 2, DateOf(Fin) + 2);
end;

procedure TfrmVistaProyectos.AjustarZoomFit(const AIni, AFin: TDateTime);
var
  Minutos, Ancho: Double;
  Px: Single;
begin
  Ancho := pnlRight.ClientWidth - 24;
  if Ancho < 200 then Ancho := 900;   // el form aun no tiene tamano real
  Minutos := (AFin - AIni) * 24 * 60;
  if Minutos <= 0 then Exit;
  Px := Ancho / Minutos;
  // Clamp al rango que admite el control (0.2 seria demasiado; permitimos menos
  // para proyectos largos usando el setter directo del control).
  if Px < 0.02 then Px := 0.02;
  if Px > 2.0 then Px := 2.0;
  FGantt.SetViewport(AIni, Px, 0);
end;

end.
