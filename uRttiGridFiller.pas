unit uRttiGridFiller;

// ============================================================================
// Helper per omplir un cxGrid de manera dinamica a partir d'un TArray<T> de
// records. Llegeix els camps del record via RTTI i crea un TClientDataSet en
// memoria amb camps tipats. El grid passa a mostrar les columnes deduides.
//
// Pensat per pantalles de diagnostic (uErpExplorer) on no volem mantenir
// un DefineColumns per cada entitat. Les pantalles CRUD de producte
// (uGestionCentres, etc.) tenen el seu propi grid amb columnes al DFM i no
// han d'usar aquest helper.
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo,
  System.Generics.Collections,
  Data.DB, Datasnap.DBClient,
  cxGridDBTableView, cxGridCustomTableView;

type
  TRttiGridFiller = class
  private
    class function CrearCampoSegunTipo(ADataSet: TClientDataSet;
      const AFieldName: string; ARttiType: TRttiType): TField;
    class procedure AsignarValor(AField: TField; const AValue: TValue);
  public
    // Buida i reconstrueix ADS amb un camp per cada camp publicat del record T,
    // omple amb les files de AItems, i regenera columnes del view.
    // AMaxColumnWidth = 0 deixa l'amplada nativa del cxGrid; >0 aplica un
    // maxim (uti per evitar columnes gegants amb descripcions llargues).
    class procedure Fill<T: record>(ADS: TClientDataSet;
      AView: TcxGridDBTableView; const AItems: TArray<T>;
      AMaxColumnWidth: Integer = 0);
  end;

implementation

class function TRttiGridFiller.CrearCampoSegunTipo(ADataSet: TClientDataSet;
  const AFieldName: string; ARttiType: TRttiType): TField;
var
  FieldDef: TFieldDef;
  Kind: TTypeKind;
  TypeName: string;
begin
  Result := nil;
  if ARttiType = nil then Exit;

  Kind := ARttiType.TypeKind;
  TypeName := ARttiType.Name;
  FieldDef := ADataSet.FieldDefs.AddFieldDef;
  FieldDef.Name := AFieldName;

  case Kind of
    tkInteger:
      FieldDef.DataType := ftInteger;
    tkInt64:
      FieldDef.DataType := ftLargeint;
    tkFloat:
      if SameText(TypeName, 'TDateTime') then
        FieldDef.DataType := ftDateTime
      else if SameText(TypeName, 'TDate') then
        FieldDef.DataType := ftDate
      else
        FieldDef.DataType := ftFloat;
    tkUString, tkString, tkLString, tkWString:
      begin
        FieldDef.DataType := ftWideString;
        FieldDef.Size := 255;
      end;
    tkEnumeration:
      if SameText(TypeName, 'Boolean') then
        FieldDef.DataType := ftBoolean
      else
      begin
        FieldDef.DataType := ftWideString;
        FieldDef.Size := 64;
      end;
    tkChar, tkWChar:
      begin
        FieldDef.DataType := ftWideString;
        FieldDef.Size := 4;
      end;
  else
    // Tipus no soportat (record/array/dynarray): saltar
    FieldDef.Free;
    Exit;
  end;
end;

class procedure TRttiGridFiller.AsignarValor(AField: TField;
  const AValue: TValue);
var
  D: TDateTime;
begin
  if AField = nil then Exit;
  if AValue.IsEmpty then
  begin
    AField.Clear;
    Exit;
  end;

  case AField.DataType of
    ftInteger, ftSmallint, ftWord:
      AField.AsInteger := AValue.AsInteger;
    ftLargeint:
      AField.AsLargeInt := AValue.AsInt64;
    ftFloat:
      AField.AsFloat := AValue.AsExtended;
    ftDateTime, ftDate:
      begin
        D := AValue.AsExtended;
        if D = 0 then AField.Clear else AField.AsDateTime := D;
      end;
    ftBoolean:
      AField.AsBoolean := AValue.AsBoolean;
    ftWideString, ftString:
      AField.AsString := AValue.ToString;
  else
    AField.AsString := AValue.ToString;
  end;
end;

class procedure TRttiGridFiller.Fill<T>(ADS: TClientDataSet;
  AView: TcxGridDBTableView; const AItems: TArray<T>;
  AMaxColumnWidth: Integer);
var
  Ctx: TRttiContext;
  RecType: TRttiType;
  Fields: TArray<TRttiField>;
  RttiField: TRttiField;
  i: Integer;
  RecValue: TValue;
  P: Pointer;
  DSField: TField;
begin
  // Reset complet del view: cal desconnectar dataset i esborrar columnes
  // explicitament; nomes Close + CreateAllItems no neteja columnes de
  // datasets previs amb una estructura diferent.
  if AView <> nil then
  begin
    AView.BeginUpdate;
    try
      AView.ClearItems;
      AView.DataController.DataSource.DataSet := nil;
    finally
      AView.EndUpdate;
    end;
  end;

  // Reset complet del dataset
  if ADS.Active then ADS.Close;
  ADS.FieldDefs.Clear;
  ADS.Fields.Clear;

  Ctx := TRttiContext.Create;
  try
    RecType := Ctx.GetType(TypeInfo(T));
    if (RecType = nil) or not (RecType is TRttiRecordType) then
      raise Exception.Create('TRttiGridFiller.Fill: T no es un record con RTTI.');

    Fields := RecType.GetFields;

    // Crear FieldDefs
    for RttiField in Fields do
      CrearCampoSegunTipo(ADS, RttiField.Name, RttiField.FieldType);

    ADS.CreateDataSet;

    // Connectar view -> dataset i regenerar columnes
    if AView <> nil then
    begin
      AView.BeginUpdate;
      try
        AView.DataController.DataSource.DataSet := ADS;
        AView.DataController.CreateAllItems(True);
        if AMaxColumnWidth > 0 then
          for i := 0 to AView.ColumnCount - 1 do
            if AView.Columns[i].Width > AMaxColumnWidth then
              AView.Columns[i].Width := AMaxColumnWidth;
      finally
        AView.EndUpdate;
      end;
    end;

    // Omplir files
    ADS.DisableControls;
    try
      for i := 0 to High(AItems) do
      begin
        P := @AItems[i];
        TValue.Make(P, RecType.Handle, RecValue);
        ADS.Append;
        try
          for RttiField in Fields do
          begin
            DSField := ADS.FindField(RttiField.Name);
            if DSField <> nil then
              AsignarValor(DSField, RttiField.GetValue(P));
          end;
          ADS.Post;
        except
          ADS.Cancel;
          raise;
        end;
      end;
    finally
      ADS.EnableControls;
    end;

    ADS.First;
  finally
    Ctx.Free;
  end;
end;

end.
