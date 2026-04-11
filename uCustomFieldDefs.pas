unit uCustomFieldDefs;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.JSON, System.Variants, System.IOUtils,
  uGanttTypes;

type
  TCustomFieldDefs = class
  private
    FDefs: TList<TCustomFieldDef>;
    FFileName: string;
    function FieldTypeToJSON(AType: TCustomFieldType): string;
    function JSONToFieldType(const S: string): TCustomFieldType;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Add(const ADef: TCustomFieldDef);
    procedure Delete(AIndex: Integer);
    procedure Update(AIndex: Integer; const ADef: TCustomFieldDef);
    procedure Move(AOldIndex, ANewIndex: Integer);

    function IndexOfField(const AFieldName: string): Integer;
    function Count: Integer;
    function GetDef(AIndex: Integer): TCustomFieldDef;
    function GetDefByName(const AFieldName: string): TCustomFieldDef;
    function GetAllDefs: TArray<TCustomFieldDef>;
    function GetVisibleDefs: TArray<TCustomFieldDef>;

    // Inicializa CustomFields de un TNodeData con valores por defecto
    procedure InitNodeCustomFields(var ANodeData: TNodeData);

    // Persistencia JSON
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string = '');

    property FileName: string read FFileName write FFileName;
  end;

implementation

{ TCustomFieldDefs }

constructor TCustomFieldDefs.Create;
begin
  inherited;
  FDefs := TList<TCustomFieldDef>.Create;
end;

destructor TCustomFieldDefs.Destroy;
begin
  FDefs.Free;
  inherited;
end;

procedure TCustomFieldDefs.Clear;
begin
  FDefs.Clear;
end;

procedure TCustomFieldDefs.Add(const ADef: TCustomFieldDef);
var
  D: TCustomFieldDef;
begin
  D := ADef;
  if D.Order = 0 then
    D.Order := FDefs.Count;
  FDefs.Add(D);
end;

procedure TCustomFieldDefs.Delete(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FDefs.Count) then
    FDefs.Delete(AIndex);
end;

procedure TCustomFieldDefs.Update(AIndex: Integer; const ADef: TCustomFieldDef);
begin
  if (AIndex >= 0) and (AIndex < FDefs.Count) then
    FDefs[AIndex] := ADef;
end;

procedure TCustomFieldDefs.Move(AOldIndex, ANewIndex: Integer);
var
  D: TCustomFieldDef;
begin
  if (AOldIndex < 0) or (AOldIndex >= FDefs.Count) then Exit;
  if (ANewIndex < 0) or (ANewIndex >= FDefs.Count) then Exit;
  D := FDefs[AOldIndex];
  FDefs.Delete(AOldIndex);
  FDefs.Insert(ANewIndex, D);
end;

function TCustomFieldDefs.IndexOfField(const AFieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to FDefs.Count - 1 do
    if SameText(FDefs[I].FieldName, AFieldName) then
      Exit(I);
  Result := -1;
end;

function TCustomFieldDefs.Count: Integer;
begin
  Result := FDefs.Count;
end;

function TCustomFieldDefs.GetDef(AIndex: Integer): TCustomFieldDef;
begin
  Result := FDefs[AIndex];
end;

function TCustomFieldDefs.GetDefByName(const AFieldName: string): TCustomFieldDef;
var
  I: Integer;
begin
  I := IndexOfField(AFieldName);
  if I >= 0 then
    Result := FDefs[I]
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
    Result.FieldName := AFieldName;
    Result.Caption := AFieldName;
    Result.FieldType := cftString;
  end;
end;

function TCustomFieldDefs.GetAllDefs: TArray<TCustomFieldDef>;
begin
  Result := FDefs.ToArray;
end;

function TCustomFieldDefs.GetVisibleDefs: TArray<TCustomFieldDef>;
var
  I, N: Integer;
begin
  N := 0;
  for I := 0 to FDefs.Count - 1 do
    if FDefs[I].Visible then
      Inc(N);
  SetLength(Result, N);
  N := 0;
  for I := 0 to FDefs.Count - 1 do
    if FDefs[I].Visible then
    begin
      Result[N] := FDefs[I];
      Inc(N);
    end;
end;

procedure TCustomFieldDefs.InitNodeCustomFields(var ANodeData: TNodeData);
var
  I: Integer;
  D: TCustomFieldDef;
  V: Variant;
begin
  for I := 0 to FDefs.Count - 1 do
  begin
    D := FDefs[I];
    V := GetCustomFieldValue(ANodeData.CustomFields, D.FieldName);
    if VarIsNull(V) or VarIsEmpty(V) then
      SetCustomFieldValue(ANodeData.CustomFields, D.FieldName, D.DefaultValue);
  end;
end;

{ JSON persistence }

function TCustomFieldDefs.FieldTypeToJSON(AType: TCustomFieldType): string;
begin
  case AType of
    cftString:  Result := 'string';
    cftInteger: Result := 'integer';
    cftFloat:   Result := 'float';
    cftDate:    Result := 'date';
    cftBoolean: Result := 'boolean';
    cftList:    Result := 'list';
  else
    Result := 'string';
  end;
end;

function TCustomFieldDefs.JSONToFieldType(const S: string): TCustomFieldType;
begin
  if SameText(S, 'integer') then Result := cftInteger
  else if SameText(S, 'float') then Result := cftFloat
  else if SameText(S, 'date') then Result := cftDate
  else if SameText(S, 'boolean') then Result := cftBoolean
  else if SameText(S, 'list') then Result := cftList
  else Result := cftString;
end;

procedure TCustomFieldDefs.LoadFromFile(const AFileName: string);
var
  JSON: string;
  JArr: TJSONArray;
  JObj: TJSONObject;
  JList: TJSONArray;
  I, J: Integer;
  D: TCustomFieldDef;
begin
  FFileName := AFileName;
  FDefs.Clear;

  if not TFile.Exists(AFileName) then
    Exit;

  JSON := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  JArr := TJSONObject.ParseJSONValue(JSON) as TJSONArray;
  if JArr = nil then Exit;
  try
    for I := 0 to JArr.Count - 1 do
    begin
      JObj := JArr.Items[I] as TJSONObject;
      FillChar(D, SizeOf(D), 0);

      D.FieldName := JObj.GetValue<string>('fieldName', '');
      D.Caption := JObj.GetValue<string>('caption', D.FieldName);
      D.FieldType := JSONToFieldType(JObj.GetValue<string>('type', 'string'));
      D.Required := JObj.GetValue<Boolean>('required', False);
      D.ReadOnly := JObj.GetValue<Boolean>('readOnly', False);
      D.Order := JObj.GetValue<Integer>('order', I);
      D.Visible := JObj.GetValue<Boolean>('visible', True);
      D.Grupo := JObj.GetValue<string>('grupo', '');
      D.Tooltip := JObj.GetValue<string>('tooltip', '');
      D.MinValue := JObj.GetValue<Double>('minValue', 0);
      D.MaxValue := JObj.GetValue<Double>('maxValue', 0);
      D.FormatMask := JObj.GetValue<string>('formatMask', '');

      // DefaultValue
      case D.FieldType of
        cftString:  D.DefaultValue := JObj.GetValue<string>('default', '');
        cftInteger: D.DefaultValue := JObj.GetValue<Integer>('default', 0);
        cftFloat:   D.DefaultValue := JObj.GetValue<Double>('default', 0.0);
        cftBoolean: D.DefaultValue := JObj.GetValue<Boolean>('default', False);
        cftDate:    D.DefaultValue := JObj.GetValue<string>('default', '');
        cftList:    D.DefaultValue := JObj.GetValue<string>('default', '');
      end;

      // ListValues
      if JObj.TryGetValue<TJSONArray>('listValues', JList) then
      begin
        SetLength(D.ListValues, JList.Count);
        for J := 0 to JList.Count - 1 do
          D.ListValues[J] := JList.Items[J].Value;
      end;

      FDefs.Add(D);
    end;
  finally
    JArr.Free;
  end;
end;

procedure TCustomFieldDefs.SaveToFile(const AFileName: string);
var
  JArr: TJSONArray;
  JObj: TJSONObject;
  JList: TJSONArray;
  I, J: Integer;
  D: TCustomFieldDef;
  FN: string;
begin
  if AFileName <> '' then
    FN := AFileName
  else
    FN := FFileName;

  if FN = '' then Exit;
  FFileName := FN;

  JArr := TJSONArray.Create;
  try
    for I := 0 to FDefs.Count - 1 do
    begin
      D := FDefs[I];
      JObj := TJSONObject.Create;
      JObj.AddPair('fieldName', D.FieldName);
      JObj.AddPair('caption', D.Caption);
      JObj.AddPair('type', FieldTypeToJSON(D.FieldType));
      JObj.AddPair('required', TJSONBool.Create(D.Required));
      JObj.AddPair('readOnly', TJSONBool.Create(D.ReadOnly));
      JObj.AddPair('order', TJSONNumber.Create(D.Order));
      JObj.AddPair('visible', TJSONBool.Create(D.Visible));
      if D.Grupo <> '' then
        JObj.AddPair('grupo', D.Grupo);
      if D.Tooltip <> '' then
        JObj.AddPair('tooltip', D.Tooltip);
      if (D.MinValue <> 0) or (D.MaxValue <> 0) then
      begin
        JObj.AddPair('minValue', TJSONNumber.Create(D.MinValue));
        JObj.AddPair('maxValue', TJSONNumber.Create(D.MaxValue));
      end;
      if D.FormatMask <> '' then
        JObj.AddPair('formatMask', D.FormatMask);

      // DefaultValue
      case D.FieldType of
        cftString, cftList, cftDate:
          if not VarIsNull(D.DefaultValue) then
            JObj.AddPair('default', VarToStr(D.DefaultValue));
        cftInteger:
          if not VarIsNull(D.DefaultValue) then
            JObj.AddPair('default', TJSONNumber.Create(Integer(D.DefaultValue)));
        cftFloat:
          if not VarIsNull(D.DefaultValue) then
            JObj.AddPair('default', TJSONNumber.Create(Double(D.DefaultValue)));
        cftBoolean:
          if not VarIsNull(D.DefaultValue) then
            JObj.AddPair('default', TJSONBool.Create(Boolean(D.DefaultValue)));
      end;

      // ListValues
      if Length(D.ListValues) > 0 then
      begin
        JList := TJSONArray.Create;
        for J := 0 to High(D.ListValues) do
          JList.Add(D.ListValues[J]);
        JObj.AddPair('listValues', JList);
      end;

      JArr.Add(JObj);
    end;

    TFile.WriteAllText(FN, JArr.Format(2), TEncoding.UTF8);
  finally
    JArr.Free;
  end;
end;

end.
