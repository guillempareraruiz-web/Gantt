unit uFestivosImportDialog;

// Dialogo para importar festivos desde plantillas JSON (Plantillas/Festivos/*.json)
// El usuario elige plantilla + año, ve la preview y confirma.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.UITypes,
  System.IOUtils, System.DateUtils, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  uCalendarsRepo;

type
  TFestivoItem = record
    Fecha: TDate;
    Descripcion: string;
  end;

  TfrmFestivosImport = class(TForm)
    pnlTop: TPanel;
    lblPlantilla: TLabel;
    cbPlantilla: TComboBox;
    lblAnio: TLabel;
    edAnio: TEdit;
    udAnio: TUpDown;
    lblInfo: TLabel;
    lbPreview: TListBox;
    pnlBottom: TPanel;
    btnImportar: TButton;
    btnCancel: TButton;
    procedure FormShow(Sender: TObject);
    procedure cbPlantillaChange(Sender: TObject);
    procedure udAnioClick(Sender: TObject; Button: TUDBtnType);
    procedure btnImportarClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FRepo: TCalendarsRepo;
    FCodigoEmpresa: SmallInt;
    FCalendarId: Integer;
    FCalendarNombre: string;
    FPlantillaFiles: TArray<string>;
    FItems: TArray<TFestivoItem>;
    procedure LoadPlantillas;
    procedure LoadPreview;
  public
    class function Execute(ARepo: TCalendarsRepo; ACodigoEmpresa: SmallInt;
      ACalendarId: Integer; const ACalendarNombre: string; AAnioInicial: Word): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmFestivosImport.Execute(ARepo: TCalendarsRepo;
  ACodigoEmpresa: SmallInt; ACalendarId: Integer;
  const ACalendarNombre: string; AAnioInicial: Word): Boolean;
var
  F: TfrmFestivosImport;
begin
  F := TfrmFestivosImport.Create(Application);
  try
    F.FRepo := ARepo;
    F.FCodigoEmpresa := ACodigoEmpresa;
    F.FCalendarId := ACalendarId;
    F.FCalendarNombre := ACalendarNombre;
    F.udAnio.Position := AAnioInicial;
    F.edAnio.Text := IntToStr(AAnioInicial);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmFestivosImport.FormShow(Sender: TObject);
begin
  Caption := 'Importar festivos - ' + FCalendarNombre;
  LoadPlantillas;
  if cbPlantilla.Items.Count > 0 then
  begin
    cbPlantilla.ItemIndex := 0;
    LoadPreview;
  end;
end;

procedure TfrmFestivosImport.LoadPlantillas;
var
  Dir: string;
  Files: TArray<string>;
  F: string;
  JV: TJSONValue;
  JO: TJSONObject;
  Nombre: string;
  Contenido: string;
begin
  cbPlantilla.Items.Clear;
  SetLength(FPlantillaFiles, 0);

  Dir := ExtractFilePath(ParamStr(0)) + 'Plantillas\Festivos';
  if not TDirectory.Exists(Dir) then
  begin
    lblInfo.Caption := 'No se encuentra la carpeta Plantillas\Festivos junto al .exe';
    Exit;
  end;

  Files := TDirectory.GetFiles(Dir, '*.json');
  for F in Files do
  begin
    try
      Contenido := TFile.ReadAllText(F, TEncoding.UTF8);
      JV := TJSONObject.ParseJSONValue(Contenido);
      if JV is TJSONObject then
      begin
        JO := TJSONObject(JV);
        Nombre := JO.GetValue<string>('nombre', ExtractFileName(F));
        cbPlantilla.Items.Add(Nombre);
        SetLength(FPlantillaFiles, Length(FPlantillaFiles) + 1);
        FPlantillaFiles[High(FPlantillaFiles)] := F;
        JV.Free;
      end;
    except
      // Ignorar plantilla corrupta
    end;
  end;
end;

procedure TfrmFestivosImport.LoadPreview;
var
  Idx: Integer;
  Contenido: string;
  JV: TJSONValue;
  JO: TJSONObject;
  Anios: TJSONObject;
  Items: TJSONArray;
  AnioStr: string;
  I: Integer;
  Item: TJSONObject;
  Rec: TFestivoItem;
begin
  lbPreview.Items.Clear;
  SetLength(FItems, 0);

  Idx := cbPlantilla.ItemIndex;
  if (Idx < 0) or (Idx > High(FPlantillaFiles)) then Exit;

  AnioStr := IntToStr(udAnio.Position);

  try
    Contenido := TFile.ReadAllText(FPlantillaFiles[Idx], TEncoding.UTF8);
    JV := TJSONObject.ParseJSONValue(Contenido);
    try
      if not (JV is TJSONObject) then Exit;
      JO := TJSONObject(JV);
      Anios := JO.GetValue('anios') as TJSONObject;
      if Anios = nil then Exit;
      Items := Anios.GetValue(AnioStr) as TJSONArray;
      if Items = nil then
      begin
        lblInfo.Caption := Format('La plantilla no tiene datos para el a'#241'o %s', [AnioStr]);
        Exit;
      end;

      for I := 0 to Items.Count - 1 do
      begin
        Item := Items.Items[I] as TJSONObject;
        if Item = nil then Continue;
        Rec.Fecha := ISO8601ToDate(Item.GetValue<string>('fecha'));
        Rec.Descripcion := Item.GetValue<string>('descripcion', '');
        SetLength(FItems, Length(FItems) + 1);
        FItems[High(FItems)] := Rec;
        lbPreview.Items.Add(
          FormatDateTime('dd/mm/yyyy', Rec.Fecha) + '  -  ' + Rec.Descripcion);
      end;

      lblInfo.Caption := Format('%d festivos en la plantilla para %s', [Length(FItems), AnioStr]);
    finally
      JV.Free;
    end;
  except
    on E: Exception do
      lblInfo.Caption := 'Error leyendo plantilla: ' + E.Message;
  end;
end;

procedure TfrmFestivosImport.cbPlantillaChange(Sender: TObject);
begin
  LoadPreview;
end;

procedure TfrmFestivosImport.udAnioClick(Sender: TObject; Button: TUDBtnType);
begin
  LoadPreview;
end;

procedure TfrmFestivosImport.btnImportarClick(Sender: TObject);
var
  I: Integer;
  Insertadas, Saltadas: Integer;
begin
  if Length(FItems) = 0 then
  begin
    ShowMessage('No hay festivos para importar.');
    Exit;
  end;

  Insertadas := 0;
  Saltadas := 0;
  for I := 0 to High(FItems) do
  begin
    try
      FRepo.AddException(FCodigoEmpresa, FCalendarId, FItems[I].Fecha,
        False, 0, 0, FItems[I].Descripcion);
      Inc(Insertadas);
    except
      // UNIQUE V031 saltarà duplicats per data: comptem com a saltada
      Inc(Saltadas);
    end;
  end;

  ShowMessage(Format('Importaci'#243'n completada.'#13#10 +
    'Insertadas: %d'#13#10 +
    'Saltadas (ya exist'#237'an): %d', [Insertadas, Saltadas]));

  ModalResult := mrOk;
end;

procedure TfrmFestivosImport.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
