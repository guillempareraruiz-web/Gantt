unit uCardLayoutSetManager;

(*
  Gestor de Card Layout Sets a BD.

  Pantalla amb cxGrid esquerra (llistat de sets visibles per a l'usuari) i
  preview a la dreta. Permet:
    - Filtrar per Tots / Privats / Comuns / Actiu
    - Marcar com a Actiu (queda persistit a FS_PL_UserPreference)
    - Editar (doble-clic o boto)
    - Nou (privat o comu) / Duplicar / Eliminar
*)

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxContainer, cxClasses, cxFilter, cxCustomData, cxData, cxDataStorage,
  cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  cxDropDownEdit,
  dxSkinsCore, dxSkinOffice2019Colorful,
  uGanttTypes, uCardLayout, uCardLayoutSetRepo, uCustomFieldDefs;

type
  TCardSetFilter = (cfAll, cfPrivate, cfCommon, cfActive);

  TfrmCardLayoutSetManager = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    lblFiltro: TLabel;
    cmbFiltro: TComboBox;
    btnNew: TButton;
    btnEdit: TButton;
    btnDuplicate: TButton;
    btnDelete: TButton;
    btnSetActive: TButton;
    pnlMain: TPanel;
    pnlLeft: TPanel;
    grid: TcxGrid;
    tv: TcxGridTableView;
    colNombre: TcxGridColumn;
    colScope: TcxGridColumn;
    colCreadoPor: TcxGridColumn;
    colActivo: TcxGridColumn;
    colFechaMod: TcxGridColumn;
    lv: TcxGridLevel;
    pnlRight: TPanel;
    lblPreview: TLabel;
    cmbPreviewCategoria: TComboBox;
    pbPreview: TPaintBox;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDuplicateClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnSetActiveClick(Sender: TObject);
    procedure tvCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure cmbFiltroChange(Sender: TObject);
    procedure cmbPreviewCategoriaChange(Sender: TObject);
    procedure pbPreviewPaint(Sender: TObject);
    procedure tvCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
    procedure tvEditValueChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure tvEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure tvFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
  private
    FRepo: TCardLayoutSetRepo;
    FCustomFieldDefs: TCustomFieldDefs;
    FMetas: TArray<TCardLayoutSetMeta>;     // tots els carregats des de BD
    FVisibleIdxs: TArray<Integer>;          // indexs de FMetas que passen el filtre
    FActiveSetId: Integer;
    FActiveDirty: Boolean;                  // true si l'Active ha canviat o s'ha editat el seu contingut
    FPreviewSet: TCardLayoutSet;
    FPreviewSetId: Integer;
    FPreviewCategoria: TCardCategory;
    FSampleData: TNodeData;
    procedure LoadAll;
    procedure RebuildGrid;
    function CurrentMeta: TCardLayoutSetMeta;
    procedure UpdatePreviewForSelection;
    procedure BuildSampleData;
    procedure UpdateButtons;
  public
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
    property ActiveDirty: Boolean read FActiveDirty;
  end;

// Retorna True si l'Active Set ha canviat o si s'ha modificat el contingut
// del set que era actiu en algun moment, perque el caller pugui recarregar.
function ShowCardLayoutSetManager(AOwner: TForm; ARepo: TCardLayoutSetRepo;
  ACustomFieldDefs: TCustomFieldDefs): Boolean;

implementation

{$R *.dfm}

uses
  uCardLayoutEditor, uModalOverlay, uLogin;

function CurrentUserIdSafe: Integer;
begin
  try
    Result := CurrentSession.UserId;
  except
    Result := 0;
  end;
end;

function ShowCardLayoutSetManager(AOwner: TForm; ARepo: TCardLayoutSetRepo;
  ACustomFieldDefs: TCustomFieldDefs): Boolean;
var
  F: TfrmCardLayoutSetManager;
begin
  F := TfrmCardLayoutSetManager.Create(AOwner);
  try
    F.FRepo := ARepo;
    F.CustomFieldDefs := ACustomFieldDefs;
    F.LoadAll;
    ShowModalWithOverlay(F, AOwner);
    Result := F.ActiveDirty;
  finally
    F.Free;
  end;
end;

procedure TfrmCardLayoutSetManager.FormCreate(Sender: TObject);
var
  C: TCardCategory;
begin
  // El boton '?' del caption se instala automaticamente via uHelpAutoInstall
  // (TopicKey = 'uCardLayoutSetManager', MD en Help/es/uCardLayoutSetManager.md).
  FActiveSetId := -1;
  FActiveDirty := False;
  FPreviewSetId := -1;
  FPreviewSet := DefaultCardLayoutSet;
  FPreviewCategoria := ccOFPend;
  BuildSampleData;

  // Combo filtre
  cmbFiltro.Items.Clear;
  cmbFiltro.Items.Add('Todos');
  cmbFiltro.Items.Add('Privados');
  cmbFiltro.Items.Add('Comunes');
  cmbFiltro.Items.Add('Activo');
  cmbFiltro.ItemIndex := 0;

  // Combo categoria del preview
  cmbPreviewCategoria.Items.Clear;
  for C := Low(TCardCategory) to High(TCardCategory) do
    cmbPreviewCategoria.Items.AddObject(CardCategoryCaption(C),
      TObject(NativeInt(Ord(C))));
  cmbPreviewCategoria.ItemIndex := 0;

  tv.OptionsSelection.CellSelect := True;
  tv.OptionsSelection.HideFocusRect := False;
  tv.OptionsView.Indicator := True;
  tv.OptionsData.Editing := True;
  tv.OptionsCustomize.ColumnFiltering := False;
  colActivo.Options.Editing := False;
  colFechaMod.Options.Editing := False;
  colScope.Options.Editing := True;
  colNombre.Options.Editing := True;
  tv.DataController.RecordCount := 0;
end;

procedure TfrmCardLayoutSetManager.FormDestroy(Sender: TObject);
begin
  // FRepo no l'eliminem: ens el passa el caller
end;

procedure TfrmCardLayoutSetManager.BuildSampleData;
begin
  FSampleData := Default(TNodeData);
  FSampleData.DataId := 1001;
  FSampleData.NumeroOrdenFabricacion := 24350;
  FSampleData.Operacion := 'CORTE';
  FSampleData.CodigoArticulo := 'ART-001';
  FSampleData.DescripcionArticulo := 'Pieza lateral izquierda';
  FSampleData.CodigoCliente := 'CLI-100';
  FSampleData.DurationMin := 180;
  FSampleData.FechaEntrega := Date + 5;
  FSampleData.FechaNecesaria := Date + 3;
  FSampleData.Prioridad := 1;
  FSampleData.Estado := neEnCurso;
  FSampleData.Tipo := ntOF;
  FSampleData.OperariosNecesarios := 3;
  FSampleData.OperariosAsignados := 2;
  FSampleData.UnidadesAFabricar := 500;
  FSampleData.UnidadesFabricadas := 120;
  FSampleData.NumeroPedido := 8800;
  FSampleData.SeriePedido := 'A';
end;

procedure TfrmCardLayoutSetManager.LoadAll;
var
  I: Integer;
  Found: Boolean;
begin
  if FRepo = nil then Exit;
  FMetas := FRepo.ListVisible;
  FActiveSetId := FRepo.GetActiveSetId;

  // Validacio: sempre ha d'haver-hi un set actiu si hi ha sets visibles.
  // Si l'actiu actual no es a la llista (esborrat / no accessible),
  // marquem el primer visible com a actiu.
  if Length(FMetas) > 0 then
  begin
    Found := False;
    for I := 0 to High(FMetas) do
      if FMetas[I].SetId = FActiveSetId then
      begin
        Found := True;
        Break;
      end;
    if not Found then
    begin
      FActiveSetId := FMetas[0].SetId;
      FRepo.SetActiveSetId(FActiveSetId);
      FActiveDirty := True;
    end;
  end;
  RebuildGrid;
end;

procedure TfrmCardLayoutSetManager.RebuildGrid;
var
  I, Filtered: Integer;
  Filt: TCardSetFilter;
begin
  if cmbFiltro.ItemIndex < 0 then
    Filt := cfAll
  else
    Filt := TCardSetFilter(cmbFiltro.ItemIndex);

  SetLength(FVisibleIdxs, Length(FMetas));
  Filtered := 0;
  for I := 0 to High(FMetas) do
  begin
    case Filt of
      cfPrivate: if FMetas[I].IsCommon then Continue;
      cfCommon:  if not FMetas[I].IsCommon then Continue;
      cfActive:  if FMetas[I].SetId <> FActiveSetId then Continue;
    end;
    FVisibleIdxs[Filtered] := I;
    Inc(Filtered);
  end;
  SetLength(FVisibleIdxs, Filtered);

  tv.BeginUpdate();
  try
    tv.DataController.RecordCount := Filtered;
    for I := 0 to Filtered - 1 do
    begin
      var M: TCardLayoutSetMeta := FMetas[FVisibleIdxs[I]];
      tv.DataController.Values[I, colNombre.Index]    := M.Nombre;
      if M.IsCommon then
        tv.DataController.Values[I, colScope.Index]   := 'Com'#250'n'
      else
        tv.DataController.Values[I, colScope.Index]   := 'Privado';
      tv.DataController.Values[I, colCreadoPor.Index] := M.CreadoPor;
      tv.DataController.Values[I, colActivo.Index]    := M.SetId = FActiveSetId;
      tv.DataController.Values[I, colFechaMod.Index]  := M.FechaModificacion;
    end;
  finally
    tv.EndUpdate;
  end;

  UpdateButtons;
  UpdatePreviewForSelection;
end;

function TfrmCardLayoutSetManager.CurrentMeta: TCardLayoutSetMeta;
var
  Row: Integer;
begin
  Result := Default(TCardLayoutSetMeta);
  Result.SetId := -1;
  Row := tv.DataController.FocusedRecordIndex;
  if (Row < 0) or (Row >= Length(FVisibleIdxs)) then Exit;
  Result := FMetas[FVisibleIdxs[Row]];
end;

procedure TfrmCardLayoutSetManager.UpdatePreviewForSelection;
var
  M: TCardLayoutSetMeta;
begin
  M := CurrentMeta;
  if M.SetId < 0 then
  begin
    FPreviewSetId := -1;
    FPreviewSet := DefaultCardLayoutSet;
  end
  else if M.SetId <> FPreviewSetId then
  begin
    FPreviewSetId := M.SetId;
    FRepo.Load(M.SetId, FPreviewSet);
  end;
  pbPreview.Invalidate;
end;

procedure TfrmCardLayoutSetManager.UpdateButtons;
var
  HasSel: Boolean;
  M: TCardLayoutSetMeta;
begin
  M := CurrentMeta;
  HasSel := M.SetId >= 0;
  btnEdit.Enabled := HasSel and not M.IsSystem;
  btnDuplicate.Enabled := HasSel;
  btnDelete.Enabled := HasSel and not M.IsSystem
    and (not M.IsCommon) and (M.UserId = CurrentUserIdSafe);
  btnSetActive.Enabled := HasSel and (M.SetId <> FActiveSetId);
end;

procedure TfrmCardLayoutSetManager.btnSetActiveClick(Sender: TObject);
var
  M: TCardLayoutSetMeta;
begin
  M := CurrentMeta;
  if M.SetId < 0 then Exit;
  if M.SetId = FActiveSetId then Exit;
  FRepo.SetActiveSetId(M.SetId);
  FActiveSetId := M.SetId;
  FActiveDirty := True;
  RebuildGrid;
end;

procedure TfrmCardLayoutSetManager.tvCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Row: Integer;
  IsActiveRow: Boolean;
begin
  if AViewInfo = nil then Exit;
  if AViewInfo.GridRecord = nil then Exit;
  Row := AViewInfo.GridRecord.RecordIndex;
  if (Row < 0) or (Row >= Length(FVisibleIdxs)) then Exit;
  IsActiveRow := FMetas[FVisibleIdxs[Row]].SetId = FActiveSetId;
  if not IsActiveRow then Exit;
  if AViewInfo.Selected or AViewInfo.Focused then Exit;
  // Verd suau per a la fila activa
  ACanvas.Brush.Color := $00D8F5D8;
  ACanvas.Font.Color := $00115C11;
  ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
end;

procedure TfrmCardLayoutSetManager.cmbFiltroChange(Sender: TObject);
begin
  RebuildGrid;
end;

procedure TfrmCardLayoutSetManager.cmbPreviewCategoriaChange(Sender: TObject);
begin
  if cmbPreviewCategoria.ItemIndex >= 0 then
    FPreviewCategoria := TCardCategory(cmbPreviewCategoria.ItemIndex);
  pbPreview.Invalidate;
end;

procedure TfrmCardLayoutSetManager.tvFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
begin
  UpdateButtons;
  UpdatePreviewForSelection;
end;

procedure TfrmCardLayoutSetManager.tvCellDblClick(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
  AShift: TShiftState; var AHandled: Boolean);
begin
  // Doble-clic obre editor nomes si NO ha estat sobre la columna Nombre
  // (la qual entra en mode edicio normal del grid).
  if (ACellViewInfo <> nil) and (ACellViewInfo.Item = colNombre) then Exit;
  btnEditClick(nil);
  AHandled := True;
end;

procedure TfrmCardLayoutSetManager.tvEditing(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
var
  Row, Idx: Integer;
  M: TCardLayoutSetMeta;
begin
  Row := tv.DataController.FocusedRecordIndex;
  if (Row < 0) or (Row >= Length(FVisibleIdxs)) then
  begin
    AAllow := False;
    Exit;
  end;
  Idx := FVisibleIdxs[Row];
  M := FMetas[Idx];

  // Activo no es editable desde el grid: cal usar el boto "Marcar como activo".
  if AItem = colActivo then
  begin
    AAllow := False;
    Exit;
  end;

  // El set Sistema no es pot editar (ni nom ni scope)
  if M.IsSystem then
  begin
    AAllow := False;
    Exit;
  end;

  AAllow := True;
end;

procedure TfrmCardLayoutSetManager.tvEditValueChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
var
  Row, Idx: Integer;
  NewNombre, NewScope: string;
  NewIsCommon: Boolean;
  S: TCardLayoutSet;
begin
  Row := tv.DataController.FocusedRecordIndex;
  if (Row < 0) or (Row >= Length(FVisibleIdxs)) then Exit;
  Idx := FVisibleIdxs[Row];

  if AItem = colNombre then
  begin
    NewNombre := VarToStr(tv.DataController.Values[Row, colNombre.Index]);
    if Trim(NewNombre) = '' then Exit;
    if NewNombre = FMetas[Idx].Nombre then Exit;
    if not FRepo.Load(FMetas[Idx].SetId, S) then Exit;
    FRepo.UpdateSet(FMetas[Idx].SetId, NewNombre, S);
    FMetas[Idx].Nombre := NewNombre;
  end
  else if AItem = colScope then
  begin
    NewScope := VarToStr(tv.DataController.Values[Row, colScope.Index]);
    NewIsCommon := SameText(NewScope, 'Com'#250'n');
    if NewIsCommon = FMetas[Idx].IsCommon then Exit;
    FRepo.ChangeScope(FMetas[Idx].SetId, NewIsCommon);
    FMetas[Idx].IsCommon := NewIsCommon;
    if NewIsCommon then FMetas[Idx].UserId := 0;
  end;
end;

procedure TfrmCardLayoutSetManager.pbPreviewPaint(Sender: TObject);
var
  R: TRect;
  Lay: TCardLayout;
  Resolver: TCardFieldResolver;
begin
  pbPreview.Canvas.Brush.Color := $00F0EDE8;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);
  Lay := FPreviewSet.Layouts[FPreviewCategoria];
  R := Rect(10, 10, pbPreview.Width - 10, 10 + Lay.CardHeight);
  if R.Bottom > pbPreview.Height - 10 then
    R.Bottom := pbPreview.Height - 10;
  if Lay.BgColor <> 0 then
    pbPreview.Canvas.Brush.Color := Lay.BgColor
  else
    pbPreview.Canvas.Brush.Color := clWhite;
  if Lay.BorderColor <> 0 then
    pbPreview.Canvas.Pen.Color := Lay.BorderColor
  else
    pbPreview.Canvas.Pen.Color := $00E0E0E0;
  if Lay.BorderWidth > 0 then
  begin
    pbPreview.Canvas.Pen.Width := Lay.BorderWidth;
    pbPreview.Canvas.Pen.Style := psSolid;
  end
  else
  begin
    pbPreview.Canvas.Pen.Style := psClear;
  end;
  pbPreview.Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom,
    Lay.CornerRadius, Lay.CornerRadius);
  pbPreview.Canvas.Pen.Style := psSolid;
  pbPreview.Canvas.Pen.Width := 1;
  Resolver := MakeNodeDataResolver(FSampleData);
  RenderCard(pbPreview.Canvas, R, Lay, Resolver);
end;

procedure TfrmCardLayoutSetManager.btnCloseClick(Sender: TObject);
begin
  Close;
end;


procedure TfrmCardLayoutSetManager.btnNewClick(Sender: TObject);
var
  F: TfrmCardLayoutEditor;
  S: TCardLayoutSet;
  Nombre: string;
  IsCommon: Boolean;
  NewId: Integer;
begin
  S := DefaultCardLayoutSet;
  F := TfrmCardLayoutEditor.Create(Self);
  try
    F.CustomFieldDefs := FCustomFieldDefs;
    F.LayoutSet := S;
    F.SetDisplayName('Nuevo layout', False);
    if ShowModalWithOverlay(F, Self) <> mrOk then Exit;
    S := F.LayoutSet;
  finally
    F.Free;
  end;

  Nombre := InputBox('Guardar Card Layout Set', 'Nombre del layout:',
    'Nuevo layout');
  if Trim(Nombre) = '' then Exit;
  IsCommon := MessageDlg(
    'Guardar como com'#250'n (visible por todos los usuarios)?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  NewId := FRepo.Insert(Nombre, IsCommon, S);
  if NewId >= 0 then
  begin
    LoadAll;
    // Focus a la nova fila
    var R: Integer;
    for R := 0 to High(FVisibleIdxs) do
      if FMetas[FVisibleIdxs[R]].SetId = NewId then
      begin
        tv.DataController.FocusedRecordIndex := R;
        Break;
      end;
  end;
end;

procedure TfrmCardLayoutSetManager.btnEditClick(Sender: TObject);
var
  M: TCardLayoutSetMeta;
  F: TfrmCardLayoutEditor;
  S: TCardLayoutSet;
begin
  M := CurrentMeta;
  if M.SetId < 0 then Exit;
  if not FRepo.Load(M.SetId, S) then Exit;

  F := TfrmCardLayoutEditor.Create(Self);
  try
    F.CustomFieldDefs := FCustomFieldDefs;
    F.LayoutSet := S;
    F.SetDisplayName(M.Nombre, M.IsCommon);
    if ShowModalWithOverlay(F, Self) <> mrOk then Exit;
    S := F.LayoutSet;
  finally
    F.Free;
  end;

  // Si es comu, demanar si vol sobreescriure o crear-ne un de privat
  if M.IsCommon then
  begin
    var Resp := MessageDlg(
      'El layout actual es com'#250'n a todos los usuarios.'#10#10 +
      'S'#237' = sobrescribir el com'#250'n'#10 +
      'No = guardar como privado',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    if Resp = mrCancel then Exit;
    if Resp = mrNo then
    begin
      var Nombre := InputBox('Guardar como privado', 'Nombre del layout:',
        M.Nombre);
      if Trim(Nombre) = '' then Exit;
      FRepo.Insert(Nombre, False, S);
    end
    else
    begin
      FRepo.UpdateSet(M.SetId, M.Nombre, S);
      if M.SetId = FActiveSetId then FActiveDirty := True;
    end;
  end
  else
  begin
    FRepo.UpdateSet(M.SetId, M.Nombre, S);
    if M.SetId = FActiveSetId then FActiveDirty := True;
  end;

  // Forcem recarrega del preview: el SetId no ha canviat pero el contingut si.
  FPreviewSetId := -1;
  LoadAll;
end;

procedure TfrmCardLayoutSetManager.btnDuplicateClick(Sender: TObject);
var
  M: TCardLayoutSetMeta;
  S: TCardLayoutSet;
  Nombre: string;
  IsCommon: Boolean;
begin
  M := CurrentMeta;
  if M.SetId < 0 then Exit;
  if not FRepo.Load(M.SetId, S) then Exit;
  Nombre := InputBox('Duplicar Card Layout Set', 'Nombre del nuevo layout:',
    M.Nombre + ' (copia)');
  if Trim(Nombre) = '' then Exit;
  IsCommon := MessageDlg(
    'Guardar como com'#250'n (visible por todos los usuarios)?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  FRepo.Insert(Nombre, IsCommon, S);
  LoadAll;
end;

procedure TfrmCardLayoutSetManager.btnDeleteClick(Sender: TObject);
var
  M: TCardLayoutSetMeta;
  Uid: Integer;
begin
  M := CurrentMeta;
  if M.SetId < 0 then Exit;
  if M.IsSystem then
  begin
    MessageDlg('El layout de sistema no se puede eliminar.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  Uid := CurrentUserIdSafe;
  // Nomes es pot eliminar si es privat de l'usuari actual.
  if M.IsCommon then
  begin
    MessageDlg('Los layouts comunes no se pueden eliminar desde aqu'#237'.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  if (Uid > 0) and (M.UserId <> Uid) then
  begin
    MessageDlg('Solo puedes eliminar layouts privados que hayas creado t'#250'.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  if Length(FMetas) <= 1 then
  begin
    MessageDlg('No se puede eliminar el '#250'nico layout existente.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  if MessageDlg('Eliminar el layout "' + M.Nombre + '"?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FRepo.Delete(M.SetId);
  LoadAll;
end;

end.
