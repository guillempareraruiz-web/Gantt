unit uGestionProyectos;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmGestionProyectos = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnNuevoEscenario: TButton;
    btnActivar: TButton;
    btnPromover: TButton;
    btnEliminar: TButton;
    btnGuardar: TButton;
    btnAsignarUsuarios: TButton;
    gridProyectos: TcxGrid;
    tvProyectos: TcxGridTableView;
    colProjId: TcxGridColumn;
    colProjCodigo: TcxGridColumn;
    colProjNombre: TcxGridColumn;
    colProjDescripcion: TcxGridColumn;
    colProjTipo: TcxGridColumn;
    colProjBasado: TcxGridColumn;
    colProjFecha: TcxGridColumn;
    colProjActivo: TcxGridColumn;
    colProjFechaBloqueo: TcxGridColumn;
    lvProyectos: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnNuevoEscenarioClick(Sender: TObject);
    procedure btnActivarClick(Sender: TObject);
    procedure btnPromoverClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnAsignarUsuariosClick(Sender: TObject);
  private
    FProjectIds: TArray<Integer>;
    FIsMaster: TArray<Boolean>;
    procedure LoadProyectos;
    function GetSelectedProjectId: Integer;
    function GetSelectedIdx: Integer;
    function IsSelectedMaster: Boolean;
    procedure ClonarProyecto(ASourceId, ANewId: Integer);
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uLogin, uAsignarUsuariosProyecto;

function TfrmGestionProyectos.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionProyectos.Exec(const ASQL: string): Integer;
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := ASQL;
    Cmd.Execute(Result, EmptyParam);
  finally
    Cmd.Free;
  end;
end;

function TfrmGestionProyectos.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TfrmGestionProyectos.FormCreate(Sender: TObject);
begin
  LoadProyectos;
end;

procedure TfrmGestionProyectos.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGestionProyectos.LoadProyectos;
var
  Q: TADOQuery;
  I: Integer;
  Tipo, Basado, Activo: string;
  IsMaster: Boolean;
  CurrentProjId: Integer;
begin
  CurrentProjId := DMPlanner.CurrentProjectId;

  tvProyectos.BeginUpdate;
  try
    tvProyectos.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT p.ProjectId, p.Codigo, p.Nombre, p.Descripcion, p.EsMaster, p.EsEscenario, ' +
      '  p.BasedOnProjectId, p.FechaCreacion, p.FechaBloqueo, p.Activo, ' +
      '  (SELECT p2.Codigo FROM FS_PL_Project p2 WHERE p2.CodigoEmpresa = p.CodigoEmpresa ' +
      '   AND p2.ProjectId = p.BasedOnProjectId) AS BasadoEn ' +
      'FROM FS_PL_Project p ' +
      'WHERE p.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY p.EsMaster DESC, p.FechaCreacion DESC');
    try
      SetLength(FProjectIds, Q.RecordCount);
      SetLength(FIsMaster, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        IsMaster := Q.FieldByName('EsMaster').AsBoolean;
        if IsMaster then
          Tipo := 'MASTER'
        else if Q.FieldByName('EsEscenario').AsBoolean then
          Tipo := 'Escenario'
        else
          Tipo := '--';

        Basado := Q.FieldByName('BasadoEn').AsString;
        if Q.FieldByName('ProjectId').AsInteger = CurrentProjId then
          Activo := 'ACTIVO'
        else
          Activo := '';

        tvProyectos.DataController.RecordCount := I + 1;
        tvProyectos.DataController.Values[I, colProjId.Index] := Q.FieldByName('ProjectId').AsInteger;
        tvProyectos.DataController.Values[I, colProjCodigo.Index] := Q.FieldByName('Codigo').AsString;
        tvProyectos.DataController.Values[I, colProjNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvProyectos.DataController.Values[I, colProjDescripcion.Index] := Q.FieldByName('Descripcion').AsString;
        tvProyectos.DataController.Values[I, colProjTipo.Index] := Tipo;
        tvProyectos.DataController.Values[I, colProjBasado.Index] := Basado;
        tvProyectos.DataController.Values[I, colProjFecha.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', Q.FieldByName('FechaCreacion').AsDateTime);
        tvProyectos.DataController.Values[I, colProjActivo.Index] := Activo;
        if Q.FieldByName('FechaBloqueo').IsNull then
          tvProyectos.DataController.Values[I, colProjFechaBloqueo.Index] := Null
        else
          tvProyectos.DataController.Values[I, colProjFechaBloqueo.Index] :=
            Q.FieldByName('FechaBloqueo').AsDateTime;

        FProjectIds[I] := Q.FieldByName('ProjectId').AsInteger;
        FIsMaster[I] := IsMaster;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvProyectos.EndUpdate;
  end;
end;

function TfrmGestionProyectos.GetSelectedIdx: Integer;
begin
  Result := -1;
  if tvProyectos.Controller.FocusedRecord <> nil then
    Result := tvProyectos.Controller.FocusedRecord.RecordIndex;
end;

function TfrmGestionProyectos.GetSelectedProjectId: Integer;
var
  Idx: Integer;
begin
  Result := -1;
  Idx := GetSelectedIdx;
  if (Idx >= 0) and (Idx <= High(FProjectIds)) then
    Result := FProjectIds[Idx];
end;

function TfrmGestionProyectos.IsSelectedMaster: Boolean;
var
  Idx: Integer;
begin
  Result := False;
  Idx := GetSelectedIdx;
  if (Idx >= 0) and (Idx <= High(FIsMaster)) then
    Result := FIsMaster[Idx];
end;

procedure TfrmGestionProyectos.ClonarProyecto(ASourceId, ANewId: Integer);
var
  CE: string;
  SrcStr, NewStr: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  SrcStr := IntToStr(ASourceId);
  NewStr := IntToStr(ANewId);

  // Los Node tienen IDENTITY, necesitamos mapear IDs viejo->nuevo via tabla temporal
  Exec(
    'CREATE TABLE #NodeMap (OldId INT PRIMARY KEY, NewId INT); ' +
    // Insertar nodos nuevos y guardar mapeo
    'DECLARE @Pairs TABLE (OldId INT, NewId INT); ' +
    'MERGE FS_PL_Node AS T ' +
    'USING (SELECT CodigoEmpresa, NodeId AS OldId, ProjectId, CenterId, FechaInicio, FechaFin, ' +
    '  DuracionMin, Caption, ColorFondo, ColorBorde, Visible, Habilitado ' +
    '  FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + SrcStr + ') AS S ' +
    'ON 1 = 0 ' +
    'WHEN NOT MATCHED THEN ' +
    '  INSERT (CodigoEmpresa, ProjectId, CenterId, FechaInicio, FechaFin, DuracionMin, ' +
    '          Caption, ColorFondo, ColorBorde, Visible, Habilitado) ' +
    '  VALUES (S.CodigoEmpresa, ' + NewStr + ', S.CenterId, S.FechaInicio, S.FechaFin, ' +
    '          S.DuracionMin, S.Caption, S.ColorFondo, S.ColorBorde, S.Visible, S.Habilitado) ' +
    'OUTPUT S.OldId, INSERTED.NodeId INTO #NodeMap; ' +

    // Copiar NodeData usando el mapeo
    'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, NumeroPedido, SeriePedido, ' +
    '  NumeroOF, SerieOF, NumeroTrabajo, FechaEntrega, FechaNecesaria, CodigoCliente, ' +
    '  CodigoColor, CodigoTalla, Stock, CodigoArticulo, DescripcionArticulo, ' +
    '  PorcentajeDependencia, UnidadesFabricadas, UnidadesAFabricar, TiempoUnidadFabSecs, ' +
    '  DuracionMin, DuracionMinOriginal, OperariosNecesarios, OperariosAsignados, ' +
    '  Estado, Tipo, Prioridad, ColorFondoOp, ColorBordeOp, LibreMovimiento) ' +
    'SELECT nd.CodigoEmpresa, nm.NewId, nd.Operacion, nd.NumeroPedido, nd.SeriePedido, ' +
    '  nd.NumeroOF, nd.SerieOF, nd.NumeroTrabajo, nd.FechaEntrega, nd.FechaNecesaria, ' +
    '  nd.CodigoCliente, nd.CodigoColor, nd.CodigoTalla, nd.Stock, nd.CodigoArticulo, ' +
    '  nd.DescripcionArticulo, nd.PorcentajeDependencia, nd.UnidadesFabricadas, ' +
    '  nd.UnidadesAFabricar, nd.TiempoUnidadFabSecs, nd.DuracionMin, nd.DuracionMinOriginal, ' +
    '  nd.OperariosNecesarios, nd.OperariosAsignados, nd.Estado, nd.Tipo, nd.Prioridad, ' +
    '  nd.ColorFondoOp, nd.ColorBordeOp, nd.LibreMovimiento ' +
    'FROM FS_PL_NodeData nd ' +
    'INNER JOIN #NodeMap nm ON nm.OldId = nd.NodeId ' +
    'WHERE nd.CodigoEmpresa = ' + CE + '; ' +

    // Copiar Dependencies
    'INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, FromNodeId, ToNodeId, TipoLink, PorcentajeDependencia) ' +
    'SELECT d.CodigoEmpresa, ' + NewStr + ', nmF.NewId, nmT.NewId, d.TipoLink, d.PorcentajeDependencia ' +
    'FROM FS_PL_Dependency d ' +
    'INNER JOIN #NodeMap nmF ON nmF.OldId = d.FromNodeId ' +
    'INNER JOIN #NodeMap nmT ON nmT.OldId = d.ToNodeId ' +
    'WHERE d.CodigoEmpresa = ' + CE + ' AND d.ProjectId = ' + SrcStr + '; ' +

    // Copiar OperatorAssignments
    'INSERT INTO FS_PL_OperatorAssignment (CodigoEmpresa, OperatorId, NodeId, Horas) ' +
    'SELECT oa.CodigoEmpresa, oa.OperatorId, nm.NewId, oa.Horas ' +
    'FROM FS_PL_OperatorAssignment oa ' +
    'INNER JOIN #NodeMap nm ON nm.OldId = oa.NodeId ' +
    'WHERE oa.CodigoEmpresa = ' + CE + '; ' +

    'DROP TABLE #NodeMap;'
  );
end;

procedure TfrmGestionProyectos.btnNuevoEscenarioClick(Sender: TObject);
var
  SourceId, NewId: Integer;
  Codigo, Nombre: string;
  Q: TADOQuery;
  CE: string;
begin
  if DMPlanner.CurrentProjectId < 0 then
  begin
    ShowMessage('No hay un proyecto activo para clonar.');
    Exit;
  end;

  // Si hay proyecto seleccionado, usarlo como origen; si no, usar el activo
  SourceId := GetSelectedProjectId;
  if SourceId < 0 then
    SourceId := DMPlanner.CurrentProjectId;

  Codigo := InputBox('Nuevo Escenario', 'Código:', 'ESC-' + FormatDateTime('yyyymmdd-hhnn', Now));
  if Codigo = '' then Exit;
  Nombre := InputBox('Nuevo Escenario', 'Nombre:', 'Escenario ' + FormatDateTime('dd/mm/yyyy hh:nn', Now));
  if Nombre = '' then Exit;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  Screen.Cursor := crHourGlass;
  try
    DMPlanner.ADOConnection.BeginTrans;
    try
      // Crear proyecto escenario
      Exec('INSERT INTO FS_PL_Project (CodigoEmpresa, Codigo, Nombre, EsEscenario, BasedOnProjectId, Activo) VALUES (' +
        CE + ', ' + QStr(Codigo) + ', ' + QStr(Nombre) + ', 1, ' + IntToStr(SourceId) + ', 1)');

      // Obtener ID del nuevo proyecto
      Q := OpenQuery('SELECT MAX(ProjectId) AS NewId FROM FS_PL_Project WHERE CodigoEmpresa = ' + CE);
      try
        NewId := Q.FieldByName('NewId').AsInteger;
      finally
        Q.Free;
      end;

      // Clonar todos los datos del proyecto origen al nuevo
      ClonarProyecto(SourceId, NewId);

      DMPlanner.ADOConnection.CommitTrans;
    except
      DMPlanner.ADOConnection.RollbackTrans;
      raise;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  ShowMessage('Escenario creado correctamente.');
  LoadProyectos;
end;

procedure TfrmGestionProyectos.btnActivarClick(Sender: TObject);
var
  ProjId: Integer;
begin
  ProjId := GetSelectedProjectId;
  if ProjId < 0 then Exit;

  DMPlanner.SetCurrentProject(ProjId);

  // Guardar preferencia del usuario
  if CurrentSession.UserId > 0 then
  begin
    Exec('IF EXISTS (SELECT 1 FROM FS_PL_UserActiveProject WHERE CodigoEmpresa = ' +
      IntToStr(DMPlanner.CodigoEmpresa) + ' AND UserId = ' + IntToStr(CurrentSession.UserId) + ') ' +
      'UPDATE FS_PL_UserActiveProject SET ProjectId = ' + IntToStr(ProjId) +
      ', FechaActualizacion = GETDATE() ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' AND UserId = ' + IntToStr(CurrentSession.UserId) + ' ' +
      'ELSE INSERT INTO FS_PL_UserActiveProject (CodigoEmpresa, UserId, ProjectId) VALUES (' +
      IntToStr(DMPlanner.CodigoEmpresa) + ', ' + IntToStr(CurrentSession.UserId) + ', ' +
      IntToStr(ProjId) + ')');
  end;

  ShowMessage('Proyecto activado: ' + DMPlanner.CurrentProjectName);
  LoadProyectos;
end;

procedure TfrmGestionProyectos.btnPromoverClick(Sender: TObject);
var
  ProjId: Integer;
  CE: string;
begin
  ProjId := GetSelectedProjectId;
  if ProjId < 0 then Exit;

  if IsSelectedMaster then
  begin
    ShowMessage('Este proyecto ya es el MASTER.');
    Exit;
  end;

  if MessageDlg('¿Promover este escenario a MASTER?' + sLineBreak +
    'El actual MASTER se convertirá en un escenario histórico.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  DMPlanner.ADOConnection.BeginTrans;
  try
    // Desmarcar MASTER actual y convertirlo en escenario
    Exec('UPDATE FS_PL_Project SET EsMaster = 0, EsEscenario = 1, FechaPromocionMaster = GETDATE() ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND EsMaster = 1');

    // Marcar el nuevo como MASTER
    Exec('UPDATE FS_PL_Project SET EsMaster = 1, EsEscenario = 0 ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + IntToStr(ProjId));

    DMPlanner.ADOConnection.CommitTrans;
  except
    DMPlanner.ADOConnection.RollbackTrans;
    raise;
  end;

  DMPlanner.LoadMasterProject;
  ShowMessage('Proyecto promovido a MASTER.');
  LoadProyectos;
end;

procedure TfrmGestionProyectos.btnEliminarClick(Sender: TObject);
var
  ProjId: Integer;
  CE: string;
begin
  ProjId := GetSelectedProjectId;
  if ProjId < 0 then Exit;

  if IsSelectedMaster then
  begin
    ShowMessage('No se puede eliminar el proyecto MASTER.' + sLineBreak +
      'Promueve primero otro escenario a MASTER.');
    Exit;
  end;

  if ProjId = DMPlanner.CurrentProjectId then
  begin
    ShowMessage('No se puede eliminar el proyecto activo. Activa otro proyecto primero.');
    Exit;
  end;

  if MessageDlg('¿Eliminar este proyecto?' + sLineBreak +
    'Se eliminarán todos sus nodos, dependencias y asignaciones.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  DMPlanner.ADOConnection.BeginTrans;
  try
    // Eliminar dependencies
    Exec('DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + IntToStr(ProjId));
    // Eliminar asignaciones de operarios y nodedata (CASCADE via NodeId)
    Exec('DELETE FROM FS_PL_OperatorAssignment WHERE CodigoEmpresa = ' + CE +
      ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + IntToStr(ProjId) + ')');
    Exec('DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' + CE +
      ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + IntToStr(ProjId) + ')');
    // Eliminar nodos
    Exec('DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + IntToStr(ProjId));
    // Eliminar proyecto
    Exec('DELETE FROM FS_PL_Project WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + IntToStr(ProjId));
    DMPlanner.ADOConnection.CommitTrans;
  except
    DMPlanner.ADOConnection.RollbackTrans;
    raise;
  end;

  LoadProyectos;
end;

procedure TfrmGestionProyectos.btnGuardarClick(Sender: TObject);
var
  I, ProjId: Integer;
  Codigo, Nombre, Descripcion, BloqueoSQL: string;
  CE: string;
  V: Variant;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  for I := 0 to tvProyectos.DataController.RecordCount - 1 do
  begin
    if I > High(FProjectIds) then Continue;
    ProjId := FProjectIds[I];
    Codigo := VarToStr(tvProyectos.DataController.Values[I, colProjCodigo.Index]);
    Nombre := VarToStr(tvProyectos.DataController.Values[I, colProjNombre.Index]);
    Descripcion := VarToStr(tvProyectos.DataController.Values[I, colProjDescripcion.Index]);
    V := tvProyectos.DataController.Values[I, colProjFechaBloqueo.Index];
    if VarIsNull(V) or VarIsEmpty(V) then
      BloqueoSQL := 'NULL'
    else
      BloqueoSQL := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', TDateTime(V)) + '''';

    if (Codigo = '') or (Nombre = '') then Continue;

    Exec('UPDATE FS_PL_Project SET ' +
      'Codigo = ' + QStr(Codigo) + ', ' +
      'Nombre = ' + QStr(Nombre) + ', ' +
      'Descripcion = ' + QStr(Descripcion) + ', ' +
      'FechaBloqueo = ' + BloqueoSQL + ', ' +
      'FechaModificacion = GETDATE() ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + IntToStr(ProjId));
  end;

  // Refrescar info del proyecto actual
  if DMPlanner.CurrentProjectId > 0 then
    DMPlanner.SetCurrentProject(DMPlanner.CurrentProjectId);

  ShowMessage('Proyectos guardados correctamente.');
  LoadProyectos;
end;

procedure TfrmGestionProyectos.btnAsignarUsuariosClick(Sender: TObject);
var
  ProjId, Idx: Integer;
  Nombre: string;
  Frm: TfrmAsignarUsuariosProyecto;
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede asignar usuarios a proyectos.');
    Exit;
  end;

  ProjId := GetSelectedProjectId;
  if ProjId < 0 then
  begin
    ShowMessage('Seleccione un proyecto.');
    Exit;
  end;

  Idx := GetSelectedIdx;
  Nombre := '';
  if Idx >= 0 then
    Nombre := VarToStr(tvProyectos.DataController.Values[Idx, colProjNombre.Index]);

  Frm := TfrmAsignarUsuariosProyecto.Create(Self);
  try
    Frm.SetProject(ProjId, Nombre);
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

end.
