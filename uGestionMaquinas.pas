unit uGestionMaquinas;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxSpinEdit, cxCalc, cxCalendar, cxContainer, cxClasses, cxFilter,
  cxDropDownEdit,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB,
  System.Generics.Collections,
  uMaquinasRepo;

type
  TfrmGestionMaquinas = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    btnConfigurarColumnas: TButton;
    gridMaquinas: TcxGrid;
    tvMaquinas: TcxGridTableView;
    colMaquinaId: TcxGridColumn;
    colMaquinaCodigo: TcxGridColumn;
    colMaquinaNombre: TcxGridColumn;
    colMaquinaTipo: TcxGridColumn;
    colMaquinaModelo: TcxGridColumn;
    colMaquinaFabricante: TcxGridColumn;
    colMaquinaNumeroSerie: TcxGridColumn;
    colMaquinaDescripcion: TcxGridColumn;
    colMaquinaFechaPM: TcxGridColumn;
    colMaquinaEfficiency: TcxGridColumn;
    colMaquinaMaxLoad: TcxGridColumn;
    colMaquinaCoste: TcxGridColumn;
    colMaquinaPlanificable: TcxGridColumn;
    colMaquinaCuelloBotella: TcxGridColumn;
    colMaquinaPrioridad: TcxGridColumn;
    colMaquinaEstado: TcxGridColumn;
    colMaquinaHoras: TcxGridColumn;
    colMaquinaFechaProxRev: TcxGridColumn;
    colMaquinaOrden: TcxGridColumn;
    colMaquinaActivo: TcxGridColumn;
    lvMaquinas: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnConfigurarColumnasClick(Sender: TObject);
  private
    type
      TMaquinaCustomCol = record
        ColumnKey: string;
        Caption: string;
        DataType: Char;
        OrderDefault: Integer;
        WidthDefault: Integer;
      end;
  private
    FRepo: TMaquinasRepo;
    FIds: TArray<Integer>;       // MaquinaId por fila (0 = nueva)
    FDeleted: TList<Integer>;    // ids eliminados pendientes
    FCustomCols: TArray<TMaquinaCustomCol>;
    FCustomColumns: TArray<TcxGridColumn>;
    FColKeyByTag: TDictionary<Integer, string>;
    function QStr(const S: string): string;
    function UserLogin: string;
    procedure LoadCustomColumnDefs;
    procedure BuildCustomColumns;
    procedure LoadGrid;
    function GetRowMaquina(ARecIdx: Integer; out AMaq: TMaquina): Boolean;
    function EncodeFieldValue(ADataType: Char; const V: Variant): string;
    function DecodeFieldValue(ADataType: Char; const S: string): Variant;
    procedure SaveCustomFieldValue(AMaquinaId: Integer; const FieldKey: string;
      ADataType: Char; const Value: Variant);
    procedure SaveCustomFieldsForRow(AMaquinaId: Integer; ARecIdx: Integer);
    procedure DefaultMaquina(out AMaq: TMaquina);
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uLogin, uMaquinasCustomCols;

const
  MAQUINAS_GRID_ID = 'MAQUINAS';

class procedure TfrmGestionMaquinas.Execute;
var
  Frm: TfrmGestionMaquinas;
begin
  Frm := TfrmGestionMaquinas.Create(nil);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

function TfrmGestionMaquinas.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionMaquinas.UserLogin: string;
begin
  Result := uLogin.CurrentSession.Login;
  if Result = '' then Result := '(anon)';
end;

procedure TfrmGestionMaquinas.DefaultMaquina(out AMaq: TMaquina);
begin
  AMaq := Default(TMaquina);
  AMaq.Id := 0;
  AMaq.Codigo := '';
  AMaq.Nombre := '';
  AMaq.Activo := True;
  AMaq.Orden := 0;
  AMaq.Descripcion := '';
  AMaq.Modelo := '';
  AMaq.NumeroSerie := '';
  AMaq.Fabricante := '';
  AMaq.TipoMaquina := '';
  AMaq.FechaPuestaEnMarcha := 0;
  AMaq.FechaPuestaEnMarchaNull := True;
  AMaq.EfficiencyFactor := 1.0;
  AMaq.MaxLoadPercent := 100;
  AMaq.CostPerHour := 0;
  AMaq.EsPlanificable := True;
  AMaq.EsCuelloBotella := False;
  AMaq.PrioridadAsignacion := 100;
  AMaq.EstadoOperativo := MAQ_ESTADO_DISPONIBLE;
  AMaq.HorasFuncionamiento := 0;
  AMaq.FechaProxRevision := 0;
  AMaq.FechaProxRevisionNull := True;
end;

procedure TfrmGestionMaquinas.FormCreate(Sender: TObject);
begin
  FRepo := TMaquinasRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  FDeleted := TList<Integer>.Create;
  FColKeyByTag := TDictionary<Integer, string>.Create;
  btnConfigurarColumnas.Visible := uLogin.IsAdmin;

  tvMaquinas.OptionsData.Editing := True;
  tvMaquinas.OptionsSelection.CellSelect := True;

  LoadCustomColumnDefs;
  BuildCustomColumns;
  LoadGrid;
end;

procedure TfrmGestionMaquinas.FormDestroy(Sender: TObject);
begin
  FColKeyByTag.Free;
  FDeleted.Free;
  FRepo.Free;
end;

procedure TfrmGestionMaquinas.btnCloseClick(Sender: TObject);
begin
  Close;
end;

// ---------------------------------------------------------------------------
// CAMPS CUSTOM - definiciones
// ---------------------------------------------------------------------------

procedure TfrmGestionMaquinas.LoadCustomColumnDefs;
var
  Q: TADOQuery;
  L: TList<TMaquinaCustomCol>;
  Def: TMaquinaCustomCol;
  DT: string;
begin
  L := TList<TMaquinaCustomCol>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ColumnKey, Caption, DataType, OrderDefault, WidthDefault ' +
      'FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND GridId = ''' + MAQUINAS_GRID_ID + '''' +
      '  AND IsCustomField = 1 AND Activo = 1 ' +
      'ORDER BY OrderDefault, ColumnKey';
    Q.Open;
    while not Q.Eof do
    begin
      Def.ColumnKey := Q.FieldByName('ColumnKey').AsString;
      Def.Caption   := Q.FieldByName('Caption').AsString;
      DT := Q.FieldByName('DataType').AsString;
      if DT = '' then Def.DataType := 'S' else Def.DataType := DT[1];
      Def.OrderDefault := Q.FieldByName('OrderDefault').AsInteger;
      Def.WidthDefault := Q.FieldByName('WidthDefault').AsInteger;
      L.Add(Def);
      Q.Next;
    end;
    FCustomCols := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

procedure TfrmGestionMaquinas.BuildCustomColumns;
var
  I, W: Integer;
  Col: TcxGridColumn;
  Cols: TList<TcxGridColumn>;
begin
  for I := High(FCustomColumns) downto 0 do
    if FCustomColumns[I] <> nil then
      FCustomColumns[I].Free;
  SetLength(FCustomColumns, 0);
  FColKeyByTag.Clear;

  Cols := TList<TcxGridColumn>.Create;
  tvMaquinas.BeginUpdate;
  try
    for I := 0 to High(FCustomCols) do
    begin
      Col := tvMaquinas.CreateColumn;
      Col.Caption := FCustomCols[I].Caption + '  '#9998;
      Col.HeaderHint := 'Campo personalizado editable. Se guarda al pulsar "Guardar cambios".';
      Col.Name := 'colx_' + FCustomCols[I].ColumnKey;
      W := FCustomCols[I].WidthDefault;
      if W < 30 then W := 120;
      Col.Width := W;
      case UpCase(FCustomCols[I].DataType) of
        'N': Col.PropertiesClass := TcxCalcEditProperties;
        'D': Col.PropertiesClass := TcxDateEditProperties;
        'B': Col.PropertiesClass := TcxCheckBoxProperties;
      else
        Col.PropertiesClass := TcxTextEditProperties;
      end;
      Col.Options.Editing := True;
      Col.Tag := tvMaquinas.ColumnCount - 1;
      FColKeyByTag.Add(Col.Tag, 'X:' + FCustomCols[I].ColumnKey);
      Cols.Add(Col);
    end;
    FCustomColumns := Cols.ToArray;

    if Length(FCustomCols) > 0 then
    begin
      tvMaquinas.OptionsBehavior.CellHints := True;
      tvMaquinas.OptionsBehavior.ColumnHeaderHints := True;
    end;
  finally
    tvMaquinas.EndUpdate;
    Cols.Free;
  end;
end;

// ---------------------------------------------------------------------------
// GRID
// ---------------------------------------------------------------------------

procedure TfrmGestionMaquinas.LoadGrid;
var
  Q: TADOQuery;
  I, J: Integer;
  MaqId: Integer;
  Sel, Joins, Alias, FldName: string;
  V: Variant;
  F: TField;
begin
  FDeleted.Clear;

  // JOIN dinamico para columnas custom: cada una como X_<key>.
  Sel := '';
  Joins := '';
  for I := 0 to High(FCustomCols) do
  begin
    Alias := 'x' + IntToStr(I);
    Sel := Sel + ', ' + Alias + '.FieldValue AS [X_' + FCustomCols[I].ColumnKey + ']';
    Joins := Joins +
      ' LEFT JOIN FS_PL_Maquina_Extra ' + Alias +
      '   ON ' + Alias + '.CodigoEmpresa = m.CodigoEmpresa' +
      '  AND ' + Alias + '.MaquinaId = m.MaquinaId' +
      '  AND ' + Alias + '.FieldKey = ' + QStr(FCustomCols[I].ColumnKey);
  end;

  tvMaquinas.BeginUpdate;
  try
    tvMaquinas.DataController.RecordCount := 0;

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT m.MaquinaId, m.Codigo, m.Nombre, m.Activo, m.Orden, ' +
        '  m.Descripcion, m.Modelo, m.NumeroSerie, m.Fabricante, m.TipoMaquina, ' +
        '  m.FechaPuestaEnMarcha, m.EfficiencyFactor, m.MaxLoadPercent, m.CostPerHour, ' +
        '  m.EsPlanificable, m.EsCuelloBotella, m.PrioridadAsignacion, m.EstadoOperativo, ' +
        '  m.HorasFuncionamiento, m.FechaProxRevision' + Sel +
        ' FROM FS_PL_Maquina m' + Joins +
        ' WHERE m.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        ' ORDER BY m.Orden, m.Codigo';
      Q.Open;

      SetLength(FIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        MaqId := Q.FieldByName('MaquinaId').AsInteger;
        tvMaquinas.DataController.RecordCount := I + 1;
        tvMaquinas.DataController.Values[I, colMaquinaId.Index]          := MaqId;
        tvMaquinas.DataController.Values[I, colMaquinaCodigo.Index]      := Q.FieldByName('Codigo').AsString;
        tvMaquinas.DataController.Values[I, colMaquinaNombre.Index]      := Q.FieldByName('Nombre').AsString;
        tvMaquinas.DataController.Values[I, colMaquinaTipo.Index]        := Q.FieldByName('TipoMaquina').AsString;
        tvMaquinas.DataController.Values[I, colMaquinaModelo.Index]      := Q.FieldByName('Modelo').AsString;
        tvMaquinas.DataController.Values[I, colMaquinaFabricante.Index]  := Q.FieldByName('Fabricante').AsString;
        tvMaquinas.DataController.Values[I, colMaquinaNumeroSerie.Index] := Q.FieldByName('NumeroSerie').AsString;
        tvMaquinas.DataController.Values[I, colMaquinaDescripcion.Index] := Q.FieldByName('Descripcion').AsString;

        F := Q.FieldByName('FechaPuestaEnMarcha');
        if F.IsNull then
          tvMaquinas.DataController.Values[I, colMaquinaFechaPM.Index] := Null
        else
          tvMaquinas.DataController.Values[I, colMaquinaFechaPM.Index] := F.AsDateTime;

        tvMaquinas.DataController.Values[I, colMaquinaEfficiency.Index]  := Q.FieldByName('EfficiencyFactor').AsFloat;
        tvMaquinas.DataController.Values[I, colMaquinaMaxLoad.Index]     := Q.FieldByName('MaxLoadPercent').AsInteger;
        tvMaquinas.DataController.Values[I, colMaquinaCoste.Index]       := Q.FieldByName('CostPerHour').AsFloat;
        tvMaquinas.DataController.Values[I, colMaquinaPlanificable.Index]   := Q.FieldByName('EsPlanificable').AsBoolean;
        tvMaquinas.DataController.Values[I, colMaquinaCuelloBotella.Index]  := Q.FieldByName('EsCuelloBotella').AsBoolean;
        tvMaquinas.DataController.Values[I, colMaquinaPrioridad.Index]   := Q.FieldByName('PrioridadAsignacion').AsInteger;
        tvMaquinas.DataController.Values[I, colMaquinaEstado.Index]      := EstadoOperativoText(Q.FieldByName('EstadoOperativo').AsInteger);
        tvMaquinas.DataController.Values[I, colMaquinaHoras.Index]       := Q.FieldByName('HorasFuncionamiento').AsFloat;

        F := Q.FieldByName('FechaProxRevision');
        if F.IsNull then
          tvMaquinas.DataController.Values[I, colMaquinaFechaProxRev.Index] := Null
        else
          tvMaquinas.DataController.Values[I, colMaquinaFechaProxRev.Index] := F.AsDateTime;

        tvMaquinas.DataController.Values[I, colMaquinaOrden.Index]  := Q.FieldByName('Orden').AsInteger;
        tvMaquinas.DataController.Values[I, colMaquinaActivo.Index] := Q.FieldByName('Activo').AsBoolean;
        FIds[I] := MaqId;

        // Volcar valores custom
        for J := 0 to High(FCustomCols) do
        begin
          FldName := 'X_' + FCustomCols[J].ColumnKey;
          if Q.FindField(FldName) <> nil then
          begin
            if Q.FieldByName(FldName).IsNull then
              tvMaquinas.DataController.Values[I, FCustomColumns[J].Index] := Null
            else
            begin
              V := DecodeFieldValue(FCustomCols[J].DataType,
                                    Q.FieldByName(FldName).AsString);
              tvMaquinas.DataController.Values[I, FCustomColumns[J].Index] := V;
            end;
          end;
        end;

        Inc(I);
        Q.Next;
      end;
      SetLength(FIds, I);
    finally
      Q.Free;
    end;
  finally
    tvMaquinas.EndUpdate;
  end;
end;

function TfrmGestionMaquinas.GetRowMaquina(ARecIdx: Integer;
  out AMaq: TMaquina): Boolean;
var
  V: Variant;
  function AsStr(AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := '' else Result := VarToStr(AV);
  end;
  function AsInt(AV: Variant; ADefault: Integer = 0): Integer;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADefault else Result := Integer(AV);
  end;
  function AsFloat(AV: Variant; ADefault: Double = 0): Double;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADefault else Result := Double(AV);
  end;
  function AsBool(AV: Variant; ADefault: Boolean = False): Boolean;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADefault else Result := Boolean(AV);
  end;
  procedure AsDate(AV: Variant; out ADt: TDateTime; out AIsNull: Boolean);
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then
    begin
      ADt := 0;
      AIsNull := True;
    end
    else
    begin
      ADt := VarToDateTime(AV);
      AIsNull := (ADt = 0);
    end;
  end;
begin
  Result := False;
  if (ARecIdx < 0) or (ARecIdx >= tvMaquinas.DataController.RecordCount) then Exit;

  DefaultMaquina(AMaq);

  if ARecIdx < Length(FIds) then
    AMaq.Id := FIds[ARecIdx]
  else
    AMaq.Id := 0;

  AMaq.Codigo := AsStr(tvMaquinas.DataController.Values[ARecIdx, colMaquinaCodigo.Index]);
  AMaq.Nombre := AsStr(tvMaquinas.DataController.Values[ARecIdx, colMaquinaNombre.Index]);
  AMaq.TipoMaquina := AsStr(tvMaquinas.DataController.Values[ARecIdx, colMaquinaTipo.Index]);
  AMaq.Modelo := AsStr(tvMaquinas.DataController.Values[ARecIdx, colMaquinaModelo.Index]);
  AMaq.Fabricante := AsStr(tvMaquinas.DataController.Values[ARecIdx, colMaquinaFabricante.Index]);
  AMaq.NumeroSerie := AsStr(tvMaquinas.DataController.Values[ARecIdx, colMaquinaNumeroSerie.Index]);
  AMaq.Descripcion := AsStr(tvMaquinas.DataController.Values[ARecIdx, colMaquinaDescripcion.Index]);

  AsDate(tvMaquinas.DataController.Values[ARecIdx, colMaquinaFechaPM.Index],
         AMaq.FechaPuestaEnMarcha, AMaq.FechaPuestaEnMarchaNull);

  AMaq.EfficiencyFactor := AsFloat(tvMaquinas.DataController.Values[ARecIdx, colMaquinaEfficiency.Index], 1.0);
  AMaq.MaxLoadPercent := AsInt(tvMaquinas.DataController.Values[ARecIdx, colMaquinaMaxLoad.Index], 100);
  AMaq.CostPerHour := AsFloat(tvMaquinas.DataController.Values[ARecIdx, colMaquinaCoste.Index], 0);

  AMaq.EsPlanificable := AsBool(tvMaquinas.DataController.Values[ARecIdx, colMaquinaPlanificable.Index], True);
  AMaq.EsCuelloBotella := AsBool(tvMaquinas.DataController.Values[ARecIdx, colMaquinaCuelloBotella.Index], False);
  AMaq.PrioridadAsignacion := AsInt(tvMaquinas.DataController.Values[ARecIdx, colMaquinaPrioridad.Index], 100);

  V := tvMaquinas.DataController.Values[ARecIdx, colMaquinaEstado.Index];
  AMaq.EstadoOperativo := TextToEstadoOperativo(AsStr(V));

  AMaq.HorasFuncionamiento := AsFloat(tvMaquinas.DataController.Values[ARecIdx, colMaquinaHoras.Index], 0);

  AsDate(tvMaquinas.DataController.Values[ARecIdx, colMaquinaFechaProxRev.Index],
         AMaq.FechaProxRevision, AMaq.FechaProxRevisionNull);

  AMaq.Orden := AsInt(tvMaquinas.DataController.Values[ARecIdx, colMaquinaOrden.Index], 0);
  AMaq.Activo := AsBool(tvMaquinas.DataController.Values[ARecIdx, colMaquinaActivo.Index], True);

  Result := True;
end;

procedure TfrmGestionMaquinas.btnAddClick(Sender: TObject);
var
  Idx, J: Integer;
begin
  Idx := tvMaquinas.DataController.AppendRecord;
  SetLength(FIds, Length(FIds) + 1);
  FIds[High(FIds)] := 0;

  tvMaquinas.DataController.Values[Idx, colMaquinaId.Index]          := 0;
  tvMaquinas.DataController.Values[Idx, colMaquinaCodigo.Index]      := '';
  tvMaquinas.DataController.Values[Idx, colMaquinaNombre.Index]      := '';
  tvMaquinas.DataController.Values[Idx, colMaquinaTipo.Index]        := '';
  tvMaquinas.DataController.Values[Idx, colMaquinaModelo.Index]      := '';
  tvMaquinas.DataController.Values[Idx, colMaquinaFabricante.Index]  := '';
  tvMaquinas.DataController.Values[Idx, colMaquinaNumeroSerie.Index] := '';
  tvMaquinas.DataController.Values[Idx, colMaquinaDescripcion.Index] := '';
  tvMaquinas.DataController.Values[Idx, colMaquinaFechaPM.Index]     := Null;
  tvMaquinas.DataController.Values[Idx, colMaquinaEfficiency.Index]  := 1.0;
  tvMaquinas.DataController.Values[Idx, colMaquinaMaxLoad.Index]     := 100;
  tvMaquinas.DataController.Values[Idx, colMaquinaCoste.Index]       := 0;
  tvMaquinas.DataController.Values[Idx, colMaquinaPlanificable.Index]  := True;
  tvMaquinas.DataController.Values[Idx, colMaquinaCuelloBotella.Index] := False;
  tvMaquinas.DataController.Values[Idx, colMaquinaPrioridad.Index]   := 100;
  tvMaquinas.DataController.Values[Idx, colMaquinaEstado.Index]      := EstadoOperativoText(MAQ_ESTADO_DISPONIBLE);
  tvMaquinas.DataController.Values[Idx, colMaquinaHoras.Index]       := 0;
  tvMaquinas.DataController.Values[Idx, colMaquinaFechaProxRev.Index]:= Null;
  tvMaquinas.DataController.Values[Idx, colMaquinaOrden.Index]       := 0;
  tvMaquinas.DataController.Values[Idx, colMaquinaActivo.Index]      := True;

  for J := 0 to High(FCustomColumns) do
    tvMaquinas.DataController.Values[Idx, FCustomColumns[J].Index] := Null;
  tvMaquinas.DataController.FocusedRecordIndex := Idx;
end;

procedure TfrmGestionMaquinas.btnDelClick(Sender: TObject);
var
  Idx, Id, I: Integer;
  NewIds: TArray<Integer>;
begin
  Idx := tvMaquinas.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  if MessageDlg('¿Eliminar la máquina seleccionada?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;

  if (Idx < Length(FIds)) then
  begin
    Id := FIds[Idx];
    if Id > 0 then
      FDeleted.Add(Id);
  end;

  SetLength(NewIds, Length(FIds) - 1);
  for I := 0 to High(FIds) do
    if I < Idx then
      NewIds[I] := FIds[I]
    else if I > Idx then
      NewIds[I - 1] := FIds[I];
  FIds := NewIds;

  tvMaquinas.DataController.DeleteRecord(Idx);
end;

// ---------------------------------------------------------------------------
// PERSISTENCIA campos custom
// ---------------------------------------------------------------------------

function TfrmGestionMaquinas.EncodeFieldValue(ADataType: Char;
  const V: Variant): string;
var
  D: Double;
  Dt: TDateTime;
begin
  Result := '';
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  case UpCase(ADataType) of
    'N':
      begin
        D := V;
        Result := FloatToStr(D, TFormatSettings.Invariant);
      end;
    'D':
      begin
        Dt := V;
        Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', Dt);
      end;
    'B':
      begin
        if Boolean(V) then Result := '1' else Result := '0';
      end;
  else
    Result := VarToStr(V);
  end;
end;

function TfrmGestionMaquinas.DecodeFieldValue(ADataType: Char;
  const S: string): Variant;
var
  D: Double;
  Dt: TDateTime;
begin
  Result := Null;
  if S = '' then Exit;
  case UpCase(ADataType) of
    'N':
      begin
        if TryStrToFloat(S, D, TFormatSettings.Invariant) then Result := D
        else if TryStrToFloat(S, D) then Result := D
        else Result := Null;
      end;
    'D':
      begin
        if TryStrToDateTime(S, Dt, TFormatSettings.Invariant) then Result := Dt
        else if TryStrToDateTime(S, Dt) then Result := Dt
        else Result := Null;
      end;
    'B':
      Result := (S = '1') or SameText(S, 'true');
  else
    Result := S;
  end;
end;

procedure TfrmGestionMaquinas.SaveCustomFieldValue(AMaquinaId: Integer;
  const FieldKey: string; ADataType: Char; const Value: Variant);
var
  Cmd: TADOCommand;
  IsEmpty: Boolean;
  StrVal: string;
begin
  if AMaquinaId <= 0 then Exit;

  IsEmpty := VarIsNull(Value) or VarIsEmpty(Value);
  if not IsEmpty then
  begin
    StrVal := EncodeFieldValue(ADataType, Value);
    if Trim(StrVal) = '' then IsEmpty := True;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    if IsEmpty then
    begin
      Cmd.CommandText :=
        'DELETE FROM FS_PL_Maquina_Extra ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        '  AND MaquinaId = ' + IntToStr(AMaquinaId) +
        '  AND FieldKey = ' + QStr(FieldKey) +
        '  AND Source = ''MANUAL''';
      Cmd.Execute;
    end
    else
    begin
      Cmd.CommandText :=
        'MERGE FS_PL_Maquina_Extra AS T ' +
        'USING (SELECT ' + IntToStr(DMPlanner.CodigoEmpresa) + ' AS CodigoEmpresa, ' +
        IntToStr(AMaquinaId) + ' AS MaquinaId, ' +
        QStr(FieldKey) + ' AS FieldKey, :V AS FieldValue, :U AS UpdatedBy) AS S ' +
        '  ON T.CodigoEmpresa = S.CodigoEmpresa AND T.MaquinaId = S.MaquinaId AND T.FieldKey = S.FieldKey ' +
        'WHEN MATCHED THEN UPDATE SET ' +
        '  FieldValue = S.FieldValue, Source = ''MANUAL'', ' +
        '  UpdatedBy = S.UpdatedBy, UpdatedAt = SYSUTCDATETIME() ' +
        'WHEN NOT MATCHED THEN INSERT (CodigoEmpresa, MaquinaId, FieldKey, FieldValue, Source, UpdatedBy, UpdatedAt) ' +
        '  VALUES (S.CodigoEmpresa, S.MaquinaId, S.FieldKey, S.FieldValue, ''MANUAL'', S.UpdatedBy, SYSUTCDATETIME());';
      Cmd.Parameters.Clear;
      with Cmd.Parameters.AddParameter do
      begin
        Name := 'V';
        DataType := ftWideMemo;
        Direction := pdInput;
        Value := StrVal;
      end;
      with Cmd.Parameters.AddParameter do
      begin
        Name := 'U';
        DataType := ftWideString;
        Direction := pdInput;
        Value := UserLogin;
      end;
      Cmd.Execute;
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmGestionMaquinas.SaveCustomFieldsForRow(AMaquinaId: Integer;
  ARecIdx: Integer);
var
  J: Integer;
  V: Variant;
begin
  if AMaquinaId <= 0 then Exit;
  for J := 0 to High(FCustomCols) do
  begin
    if J > High(FCustomColumns) then Continue;
    V := tvMaquinas.DataController.Values[ARecIdx, FCustomColumns[J].Index];
    SaveCustomFieldValue(AMaquinaId, FCustomCols[J].ColumnKey,
                         FCustomCols[J].DataType, V);
  end;
end;

procedure TfrmGestionMaquinas.btnSaveClick(Sender: TObject);
var
  I, NewId: Integer;
  Maq: TMaquina;
begin
  for I := 0 to FDeleted.Count - 1 do
    FRepo.Delete(FDeleted[I]);
  FDeleted.Clear;

  for I := 0 to tvMaquinas.DataController.RecordCount - 1 do
  begin
    if not GetRowMaquina(I, Maq) then Continue;
    if Trim(Maq.Codigo) = '' then Continue;

    if Maq.Id <= 0 then
    begin
      NewId := FRepo.Insert(Maq);
      if I < Length(FIds) then
        FIds[I] := NewId;
      tvMaquinas.DataController.Values[I, colMaquinaId.Index] := NewId;
      Maq.Id := NewId;
    end
    else
      FRepo.Update(Maq);

    SaveCustomFieldsForRow(Maq.Id, I);
  end;

  LoadGrid;
  ShowMessage('Cambios guardados.');
end;

procedure TfrmGestionMaquinas.btnConfigurarColumnasClick(Sender: TObject);
begin
  if uMaquinasCustomCols.TfrmMaquinasCustomCols.Execute then
  begin
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadGrid;
  end;
end;

end.
