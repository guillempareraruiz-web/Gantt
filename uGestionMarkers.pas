unit uGestionMarkers;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxCalendar, cxButtonEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB, dxSkinBasic, dxSkinBlack, dxSkinBlue,
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
  TfrmGestionMarkers = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnEdit: TButton;
    btnDel: TButton;
    btnSave: TButton;
    gridMarkers: TcxGrid;
    tvMarkers: TcxGridTableView;
    colId: TcxGridColumn;
    colCaption: TcxGridColumn;
    colFechaHora: TcxGridColumn;
    colColor: TcxGridColumn;
    colVisible: TcxGridColumn;
    colMovible: TcxGridColumn;
    lvMarkers: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    ColorDialog: TColorDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure tvMarkersDblClick(Sender: TObject);
    procedure colColorCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure colColorButtonClick(Sender: TObject; AButtonIndex: Integer);
  private
    FIds: TArray<Integer>;
    FColors: TArray<Integer>;
    procedure LoadMarkers;
    function GetSelectedIdx: Integer;
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uMarkerEditor, uGanttTypes, uHelpViewer;

function TfrmGestionMarkers.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionMarkers.Exec(const ASQL: string): Integer;
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

function TfrmGestionMarkers.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TfrmGestionMarkers.FormCreate(Sender: TObject);
begin
  if DMPlanner.CurrentProjectName <> '' then
    lblSubtitle.Caption := 'Proyecto: ' + DMPlanner.CurrentProjectName;
  LoadMarkers;
  // Boton '?' en el caption + F1 = ayuda contextual (mismo patron que el resto
  // de pantallas). Requiere BorderStyle = bsDialog para que el icono se muestre.
  THelpViewer.InstallHelp(Self, 'uGestionMarkers', 'Gesti'#243'n de Marcadores');
end;

procedure TfrmGestionMarkers.LoadMarkers;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvMarkers.BeginUpdate;
  try
    tvMarkers.DataController.RecordCount := 0;
    SetLength(FIds, 0);
    SetLength(FColors, 0);

    if DMPlanner.CurrentProjectId <= 0 then Exit;

    Q := OpenQuery(
      'SELECT MarkerId, ISNULL(Caption, '''') AS Caption, FechaHora, ' +
      '  ISNULL(Color, 0) AS Color, Visible, Movible ' +
      'FROM FS_PL_Marker ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId) +
      ' ORDER BY FechaHora');
    try
      SetLength(FIds, Q.RecordCount);
      SetLength(FColors, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvMarkers.DataController.RecordCount := I + 1;
        tvMarkers.DataController.Values[I, colId.Index] := Q.FieldByName('MarkerId').AsInteger;
        tvMarkers.DataController.Values[I, colCaption.Index] := Q.FieldByName('Caption').AsString;
        tvMarkers.DataController.Values[I, colFechaHora.Index] := Q.FieldByName('FechaHora').AsDateTime;
        tvMarkers.DataController.Values[I, colColor.Index] := '';
        tvMarkers.DataController.Values[I, colVisible.Index] := Q.FieldByName('Visible').AsBoolean;
        tvMarkers.DataController.Values[I, colMovible.Index] := Q.FieldByName('Movible').AsBoolean;
        FIds[I] := Q.FieldByName('MarkerId').AsInteger;
        FColors[I] := Q.FieldByName('Color').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvMarkers.EndUpdate;
  end;
end;

procedure TfrmGestionMarkers.colColorCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  R: TRect;
begin
  ADone := False;
  if AViewInfo.GridRecord = nil then Exit;
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if (RecIdx < 0) or (RecIdx > High(FColors)) then Exit;
  if FColors[RecIdx] = 0 then Exit;
  R := AViewInfo.ContentBounds;
  InflateRect(R, -2, -2);
  Dec(R.Right, 22);
  ACanvas.Brush.Color := TColor(FColors[RecIdx]);
  ACanvas.FillRect(R);
  ADone := True;
end;

procedure TfrmGestionMarkers.colColorButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  Idx: Integer;
begin
  Idx := GetSelectedIdx;
  if (Idx < 0) or (Idx > High(FColors)) then Exit;
  if FColors[Idx] <> 0 then
    ColorDialog.Color := TColor(FColors[Idx])
  else
    ColorDialog.Color := clWhite;
  if ColorDialog.Execute then
  begin
    FColors[Idx] := Integer(ColorDialog.Color);
    gridMarkers.Invalidate;
  end;
end;

function TfrmGestionMarkers.GetSelectedIdx: Integer;
begin
  Result := tvMarkers.Controller.FocusedRecordIndex;
end;

procedure TfrmGestionMarkers.btnAddClick(Sender: TObject);
var
  Caption: string;
  Q: TADOQuery;
  NewId, Cnt: Integer;
  CE, PID: string;
begin
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('No hay proyecto activo.');
    Exit;
  end;

  Caption := InputBox('Nuevo Marcador', 'Texto:', '');
  if Caption = '' then Exit;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(DMPlanner.CurrentProjectId);

  Exec('INSERT INTO FS_PL_Marker (CodigoEmpresa, ProjectId, FechaHora, Caption) VALUES (' +
    CE + ', ' + PID + ', GETDATE(), ' + QStr(Caption) + ')');

  Q := OpenQuery('SELECT MAX(MarkerId) AS NewId FROM FS_PL_Marker WHERE CodigoEmpresa = ' +
    CE + ' AND ProjectId = ' + PID);
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  Cnt := tvMarkers.DataController.RecordCount;
  tvMarkers.DataController.RecordCount := Cnt + 1;
  tvMarkers.DataController.Values[Cnt, colId.Index] := NewId;
  tvMarkers.DataController.Values[Cnt, colCaption.Index] := Caption;
  tvMarkers.DataController.Values[Cnt, colFechaHora.Index] := Now;
  tvMarkers.DataController.Values[Cnt, colColor.Index] := '';
  tvMarkers.DataController.Values[Cnt, colVisible.Index] := True;
  tvMarkers.DataController.Values[Cnt, colMovible.Index] := False;

  SetLength(FIds, Cnt + 1);
  SetLength(FColors, Cnt + 1);
  FIds[Cnt] := NewId;
  FColors[Cnt] := 0;
  tvMarkers.Controller.FocusedRecordIndex := Cnt;
end;

procedure TfrmGestionMarkers.tvMarkersDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

procedure TfrmGestionMarkers.btnEditClick(Sender: TObject);
var
  Idx, MarkerId: Integer;
  M: TGanttMarker;
  Q: TADOQuery;
  res: TMarkerEditorResult;
  CE: string;
  FontStyleByte: Integer;
begin
  Idx := GetSelectedIdx;
  if (Idx < 0) or (Idx > High(FIds)) then
  begin
    ShowMessage('Selecciona un marcador.');
    Exit;
  end;
  MarkerId := FIds[Idx];
  CE := IntToStr(DMPlanner.CodigoEmpresa);

  // Cargar el marcador COMPLETO desde BD (la grid solo muestra 6 campos; el
  // editor edita todos: estilo, grosor, fuente, orientacion/alineacion texto...).
  M := Default(TGanttMarker);
  Q := OpenQuery(
    'SELECT MarkerId, ISNULL(Caption, '''') AS Caption, FechaHora, ' +
    '  ISNULL(Color, 0) AS Color, ISNULL(Estilo, 0) AS Estilo, ' +
    '  ISNULL(GrosorLinea, 1) AS GrosorLinea, Movible, Visible, ISNULL(Tag, 0) AS Tag, ' +
    '  ISNULL(FontName, '''') AS FontName, ISNULL(FontSize, 9) AS FontSize, ' +
    '  ISNULL(FontColor, 0) AS FontColor, ISNULL(FontStyle, 0) AS FontStyle, ' +
    '  ISNULL(OrientacionTexto, 0) AS OrientacionTexto, ' +
    '  ISNULL(AlineacionTexto, 0) AS AlineacionTexto ' +
    'FROM FS_PL_Marker ' +
    'WHERE CodigoEmpresa = ' + CE + ' AND MarkerId = ' + IntToStr(MarkerId));
  try
    if Q.Eof then Exit;
    M.Id := Q.FieldByName('MarkerId').AsInteger;
    M.Caption := Q.FieldByName('Caption').AsString;
    M.DateTime := Q.FieldByName('FechaHora').AsDateTime;
    M.Color := TColor(Q.FieldByName('Color').AsInteger);
    M.Style := TMarkerStyle(Q.FieldByName('Estilo').AsInteger);
    M.StrokeWidth := Q.FieldByName('GrosorLinea').AsFloat;
    if M.StrokeWidth <= 0 then M.StrokeWidth := 1;
    M.Moveable := Q.FieldByName('Movible').AsBoolean;
    M.Visible := Q.FieldByName('Visible').AsBoolean;
    M.Tag := Q.FieldByName('Tag').AsInteger;
    M.FontName := Q.FieldByName('FontName').AsString;
    M.FontSize := Q.FieldByName('FontSize').AsInteger;
    M.FontColor := TColor(Q.FieldByName('FontColor').AsInteger);
    M.FontStyle := TFontStyles(Byte(Q.FieldByName('FontStyle').AsInteger));
    M.TextOrientation := TMarkerTextOrientation(Q.FieldByName('OrientacionTexto').AsInteger);
    M.TextAlign := TMarkerTextAlign(Q.FieldByName('AlineacionTexto').AsInteger);
  finally
    Q.Free;
  end;

  res := TfrmMarkerEditor.Execute(M);
  case res of
    merOK:
    begin
      FontStyleByte := Byte(M.FontStyle);
      Exec('UPDATE FS_PL_Marker SET ' +
        'Caption = ' + QStr(M.Caption) + ', ' +
        'FechaHora = ''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', M.DateTime) + ''', ' +
        'Color = ' + IntToStr(Integer(M.Color)) + ', ' +
        'Estilo = ' + IntToStr(Ord(M.Style)) + ', ' +
        'GrosorLinea = ' + FloatToStr(M.StrokeWidth, TFormatSettings.Invariant) + ', ' +
        'Movible = ' + IntToStr(Ord(M.Moveable)) + ', ' +
        'Visible = ' + IntToStr(Ord(M.Visible)) + ', ' +
        'Tag = ' + IntToStr(M.Tag) + ', ' +
        'FontName = ' + QStr(M.FontName) + ', ' +
        'FontSize = ' + IntToStr(M.FontSize) + ', ' +
        'FontColor = ' + IntToStr(Integer(M.FontColor)) + ', ' +
        'FontStyle = ' + IntToStr(FontStyleByte) + ', ' +
        'OrientacionTexto = ' + IntToStr(Ord(M.TextOrientation)) + ', ' +
        'AlineacionTexto = ' + IntToStr(Ord(M.TextAlign)) +
        ' WHERE CodigoEmpresa = ' + CE + ' AND MarkerId = ' + IntToStr(MarkerId));
      LoadMarkers;
    end;
    merDelete:
    begin
      Exec('DELETE FROM FS_PL_Marker WHERE CodigoEmpresa = ' + CE +
        ' AND MarkerId = ' + IntToStr(MarkerId));
      LoadMarkers;
    end;
  end;
end;

procedure TfrmGestionMarkers.btnDelClick(Sender: TObject);
var
  Idx, MarkerId: Integer;
begin
  Idx := GetSelectedIdx;
  if (Idx < 0) or (Idx > High(FIds)) then Exit;
  if MessageDlg('¿Eliminar este marcador?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  MarkerId := FIds[Idx];
  Exec('DELETE FROM FS_PL_Marker WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND MarkerId = ' + IntToStr(MarkerId));
  LoadMarkers;
end;

procedure TfrmGestionMarkers.btnSaveClick(Sender: TObject);
var
  I, MarkerId: Integer;
  Caption: string;
  FechaHora: TDateTime;
  Visible, Movible: Boolean;
  V: Variant;
  CE: string;
  Paso: string;

  function AsBool(AV: Variant): Boolean;
  begin
    Result := False;
    if VarIsNull(AV) or VarIsEmpty(AV) then Exit;
    try
      Result := Boolean(AV);
    except
      try
        Result := StrToBoolDef(VarToStr(AV), False);
      except
        Result := False;
      end;
    end;
  end;

begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  Paso := '';
  try
    for I := 0 to tvMarkers.DataController.RecordCount - 1 do
    begin
      if I > High(FIds) then Continue;
      MarkerId := FIds[I];

      Paso := Format('fila %d - Caption', [I]);
      Caption := VarToStr(tvMarkers.DataController.Values[I, colCaption.Index]);

      Paso := Format('fila %d - FechaHora (variant)', [I]);
      V := tvMarkers.DataController.Values[I, colFechaHora.Index];
      if VarIsNull(V) or VarIsEmpty(V) then Continue;

      Paso := Format('fila %d - FechaHora VarToDateTime (tipo=%d, valor="%s")',
        [I, VarType(V), VarToStr(V)]);
      try
        FechaHora := VarToDateTime(V);
      except
        Continue;
      end;

      Paso := Format('fila %d - Visible', [I]);
      Visible := AsBool(tvMarkers.DataController.Values[I, colVisible.Index]);

      Paso := Format('fila %d - Movible', [I]);
      Movible := AsBool(tvMarkers.DataController.Values[I, colMovible.Index]);

      Paso := Format('fila %d - UPDATE SQL', [I]);
      Exec('UPDATE FS_PL_Marker SET ' +
        'Caption = ' + QStr(Caption) + ', ' +
        'FechaHora = ''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FechaHora) + ''', ' +
        'Color = ' + IntToStr(FColors[I]) + ', ' +
        'Visible = ' + IntToStr(Ord(Visible)) + ', ' +
        'Movible = ' + IntToStr(Ord(Movible)) +
        ' WHERE CodigoEmpresa = ' + CE + ' AND MarkerId = ' + IntToStr(MarkerId));
    end;
    ShowMessage('Marcadores guardados correctamente.');
    LoadMarkers;
  except
    on E: Exception do
      raise Exception.Create('Error en ' + Paso + ': ' + E.Message);
  end;
end;

end.
