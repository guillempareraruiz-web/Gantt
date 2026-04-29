unit uCentresRepo;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics,
  Data.Win.ADODB, Data.DB,
  uGanttTypes, uCentreCalendar, uCalendarsRepo;

type
  TCentresRepo = class
  private
    FConnection: TADOConnection;
    FCalendarsRepo: TCalendarsRepo;
    FCentres: TArray<TCentreTreball>;
    FCentreCalendarId: TDictionary<Integer, Integer>;
    procedure LoadCenterCalendarMap(ACodigoEmpresa: SmallInt);
  public
    constructor Create(AConnection: TADOConnection;
      ACalendarsRepo: TCalendarsRepo);
    destructor Destroy; override;

    procedure LoadFromDB(ACodigoEmpresa: SmallInt);
    procedure Clear;

    function Count: Integer;
    function GetAll: TArray<TCentreTreball>;
    function GetCalendarIdFor(ACenterId: Integer): Integer;
    function GetCalendarFor(ACenterId: Integer): TCentreCalendar;

    // Persistir cambios de un centro a BD y actualizar la copia en memoria.
    procedure Update(ACodigoEmpresa: SmallInt; const ACentre: TCentreTreball);
  end;

implementation

constructor TCentresRepo.Create(AConnection: TADOConnection;
  ACalendarsRepo: TCalendarsRepo);
begin
  inherited Create;
  FConnection := AConnection;
  FCalendarsRepo := ACalendarsRepo;
  FCentreCalendarId := TDictionary<Integer, Integer>.Create;
  SetLength(FCentres, 0);
end;

destructor TCentresRepo.Destroy;
begin
  FCentreCalendarId.Free;
  inherited;
end;

procedure TCentresRepo.Clear;
begin
  SetLength(FCentres, 0);
  FCentreCalendarId.Clear;
end;

function TCentresRepo.Count: Integer;
begin
  Result := Length(FCentres);
end;

function TCentresRepo.GetAll: TArray<TCentreTreball>;
begin
  Result := FCentres;
end;

function TCentresRepo.GetCalendarIdFor(ACenterId: Integer): Integer;
begin
  if not FCentreCalendarId.TryGetValue(ACenterId, Result) then
    Result := -1;
end;

function TCentresRepo.GetCalendarFor(ACenterId: Integer): TCentreCalendar;
var
  CalId: Integer;
begin
  Result := nil;
  CalId := GetCalendarIdFor(ACenterId);
  if (CalId > 0) and (FCalendarsRepo <> nil) then
    Result := FCalendarsRepo.GetById(CalId);
end;

procedure TCentresRepo.Update(ACodigoEmpresa: SmallInt;
  const ACentre: TCentreTreball);
var
  Cmd: TADOCommand;
  I: Integer;
begin
  if FConnection = nil then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    Cmd.CommandText :=
      'UPDATE FS_PL_Center SET ' +
      '  CodigoCentro = ''' + StringReplace(ACentre.CodiCentre, '''', '''''', [rfReplaceAll]) + ''', ' +
      '  Titulo = ''' + StringReplace(ACentre.Titulo, '''', '''''', [rfReplaceAll]) + ''', ' +
      '  Subtitulo = ''' + StringReplace(ACentre.Subtitulo, '''', '''''', [rfReplaceAll]) + ''', ' +
      '  EsSecuencial = ' + IntToStr(Ord(ACentre.IsSequencial)) + ', ' +
      '  MaxLanes = ' + IntToStr(ACentre.MaxLaneCount) + ', ' +
      '  AlturaBase = ' + FloatToStr(ACentre.BaseHeight).Replace(',', '.') + ', ' +
      '  Orden = ' + IntToStr(ACentre.Order) + ', ' +
      '  Visible = ' + IntToStr(Ord(ACentre.Visible)) + ', ' +
      '  Habilitado = ' + IntToStr(Ord(ACentre.Enabled)) + ', ' +
      '  ColorFondo = ' + IntToStr(Integer(ACentre.BkColor)) +
      ' WHERE CodigoEmpresa = ' + IntToStr(ACodigoEmpresa) +
      '   AND CenterId = ' + IntToStr(ACentre.Id);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  for I := 0 to High(FCentres) do
    if FCentres[I].Id = ACentre.Id then
    begin
      FCentres[I] := ACentre;
      Break;
    end;
end;

procedure TCentresRepo.LoadFromDB(ACodigoEmpresa: SmallInt);
var
  Q: TADOQuery;
  I: Integer;
  C: TCentreTreball;
begin
  Clear;
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT c.CenterId, c.CodigoCentro, c.Titulo, c.Subtitulo, ' +
      '  c.EsSecuencial, c.MaxLanes, c.AlturaBase, c.Orden, ' +
      '  c.Visible, c.Habilitado, c.ColorFondo, ' +
      '  ISNULL(a.Nombre, '''') AS AreaNombre ' +
      'FROM FS_PL_Center c ' +
      'LEFT JOIN FS_PL_Area a ON a.CodigoEmpresa = c.CodigoEmpresa ' +
      '  AND a.AreaId = c.AreaId ' +
      'WHERE c.CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY c.Orden, c.CenterId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := ACodigoEmpresa;
    Q.Open;

    SetLength(FCentres, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      C.Id := Q.FieldByName('CenterId').AsInteger;
      C.CodiCentre := Q.FieldByName('CodigoCentro').AsString;
      C.Titulo := Q.FieldByName('Titulo').AsString;
      C.Subtitulo := Q.FieldByName('Subtitulo').AsString;
      C.IsSequencial := Q.FieldByName('EsSecuencial').AsBoolean;
      C.MaxLaneCount := Q.FieldByName('MaxLanes').AsInteger;
      C.BaseHeight := Q.FieldByName('AlturaBase').AsFloat;
      C.Order := Q.FieldByName('Orden').AsInteger;
      C.Visible := Q.FieldByName('Visible').AsBoolean;
      C.Enabled := Q.FieldByName('Habilitado').AsBoolean;
      if Q.FieldByName('ColorFondo').IsNull then
        C.BkColor := clWhite
      else
        C.BkColor := TColor(Q.FieldByName('ColorFondo').AsInteger);
      C.Area := Q.FieldByName('AreaNombre').AsString;

      FCentres[I] := C;
      Inc(I);
      Q.Next;
    end;
    SetLength(FCentres, I);
  finally
    Q.Free;
  end;

  LoadCenterCalendarMap(ACodigoEmpresa);
end;

procedure TCentresRepo.LoadCenterCalendarMap(ACodigoEmpresa: SmallInt);
var
  Q: TADOQuery;
  CenterId, CalendarId: Integer;
begin
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // Modelo 1:1 efectivo: para cada centro tomamos el primer calendario asociado
    Q.SQL.Text :=
      'SELECT CenterId, MIN(CalendarId) AS CalendarId ' +
      'FROM FS_PL_CenterCalendar ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa ' +
      'GROUP BY CenterId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := ACodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      CenterId := Q.FieldByName('CenterId').AsInteger;
      CalendarId := Q.FieldByName('CalendarId').AsInteger;
      FCentreCalendarId.AddOrSetValue(CenterId, CalendarId);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.
