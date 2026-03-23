unit uAssignOperaris;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxSpinEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinMetropolis, dxSkinOffice2019Colorful,
  dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolisDark,
  dxSkinMoneyTwins, dxSkinOffice2007Black, dxSkinOffice2007Blue,
  dxSkinOffice2007Green, dxSkinOffice2007Pink, dxSkinOffice2007Silver,
  dxSkinOffice2010Black, dxSkinOffice2010Blue, dxSkinOffice2010Silver,
  dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray, dxSkinOffice2013White,
  dxSkinOffice2016Colorful, dxSkinOffice2016Dark, dxSkinOffice2019Black,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue,
  dxScrollbarAnnotations,
  // Project
  uGanttTypes, uNodeDataRepo, uOperariosTypes, uOperariosRepo, cxCustomData,
  cxData, cxDataStorage, cxNavigator, dxDateRanges;

type
  TfrmAssignOperaris = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    chkDarkMode: TCheckBox;
    shpHeaderLine: TShape;
    pnlBottom: TPanel;
    lblResumen: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    splCenter: TSplitter;
    pnlAssignats: TPanel;
    lblAssignats: TLabel;
    gridAssignats: TcxGrid;
    tvAssignats: TcxGridTableView;
    colAsigId: TcxGridColumn;
    colAsigNombre: TcxGridColumn;
    colAsigHoras: TcxGridColumn;
    colAsigCapacitats: TcxGridColumn;
    lvAssignats: TcxGridLevel;
    pnlDisponibles: TPanel;
    lblDisponibles: TLabel;
    gridDisponibles: TcxGrid;
    tvDisponibles: TcxGridTableView;
    colDispId: TcxGridColumn;
    colDispNombre: TcxGridColumn;
    colDispCalendario: TcxGridColumn;
    colDispCapacitats: TcxGridColumn;
    lvDisponibles: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure chkDarkModeClick(Sender: TObject);
  private
    FRepo: TOperariosRepo;
    FDataId: Integer;          // nodo principal (para modo single)
    FDataIds: TArray<Integer>; // todos los DataIds (single o multi)
    FOperacion: string;
    FDurationMin: Double;
    FOperariosNecesarios: Integer;
    FResultAssignats: Integer;
    FchkSoloCapacitados: TCheckBox;

    procedure LoadGrids;
    procedure LoadAssignats;
    procedure LoadDisponibles;
    procedure SoloCapacitadosClick(Sender: TObject);
    procedure UpdateResumen;
    procedure ApplyDarkMode(ADark: Boolean);

    procedure DoAssignar(Sender: TObject);
    procedure DoDesassignar(Sender: TObject);
    procedure DoHorasEditValueChanged(Sender: TObject);

    function CapacitacionsStr(OperarioId: Integer): string;
  public
    class function Execute(
      ARepo: TOperariosRepo;
      const ADataId: Integer;
      const AOperacion: string;
      const ADurationMin: Double;
      const AOperariosNecesarios: Integer;
      out AOperarisAssignats: Integer): Boolean;

    class function ExecuteMulti(
      ARepo: TOperariosRepo;
      const ADataIds: TArray<Integer>;
      const AOperaciones: TArray<string>;
      const ATotalDurationMin: Double;
      const ATotalNecesarios: Integer): Boolean;
  end;

var
  frmAssignOperaris: TfrmAssignOperaris;

implementation

{$R *.dfm}

{ TfrmAssignOperaris }

class function TfrmAssignOperaris.Execute(
  ARepo: TOperariosRepo;
  const ADataId: Integer;
  const AOperacion: string;
  const ADurationMin: Double;
  const AOperariosNecesarios: Integer;
  out AOperarisAssignats: Integer): Boolean;
var
  F: TfrmAssignOperaris;
begin
  F := TfrmAssignOperaris.Create(Application);
  try
    F.FRepo := ARepo;
    F.FDataId := ADataId;
    SetLength(F.FDataIds, 1);
    F.FDataIds[0] := ADataId;
    F.FOperacion := AOperacion;
    F.FDurationMin := ADurationMin;
    F.FOperariosNecesarios := AOperariosNecesarios;

    F.lblTitle.Caption := 'Asignar Operarios a: ' + AOperacion;
    F.lblSubtitle.Caption := Format('DataId: %d  |  Duraci'#243'n: %.1f min  |  Necesarios: %d',
      [ADataId, ADurationMin, AOperariosNecesarios]);

    F.LoadGrids;
    F.UpdateResumen;

    Result := F.ShowModal = mrOk;
    if Result then
      AOperarisAssignats := F.FResultAssignats;
  finally
    F.Free;
  end;
end;

class function TfrmAssignOperaris.ExecuteMulti(
  ARepo: TOperariosRepo;
  const ADataIds: TArray<Integer>;
  const AOperaciones: TArray<string>;
  const ATotalDurationMin: Double;
  const ATotalNecesarios: Integer): Boolean;
var
  F: TfrmAssignOperaris;
begin
  F := TfrmAssignOperaris.Create(Application);
  try
    F.FRepo := ARepo;
    F.FDataId := ADataIds[0]; // principal para consultas
    F.FDataIds := Copy(ADataIds);
    F.FOperacion := ''; // multi-operación: no filtrar por una sola
    F.FDurationMin := ATotalDurationMin;
    F.FOperariosNecesarios := ATotalNecesarios;

    F.lblTitle.Caption := Format('Asignar Operarios a %d operaciones', [Length(ADataIds)]);
    F.lblSubtitle.Caption := Format('Duraci'#243'n total: %.1f min  |  Necesarios total: %d',
      [ATotalDurationMin, ATotalNecesarios]);

    F.LoadGrids;
    F.UpdateResumen;

    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmAssignOperaris.FormCreate(Sender: TObject);
begin
  // Configurar events del grid Disponibles (doble-clic per assignar)
  tvDisponibles.OnDblClick := DoAssignar;
  tvAssignats.OnDblClick := DoDesassignar;

  // Event edició hores: assignar a OnEditValueChanged del SpinEdit
  (colAsigHoras.Properties as TcxSpinEditProperties).OnEditValueChanged := DoHorasEditValueChanged;

  // SpinEdit per hores: mínim 0.5, increment 0.5
  with (colAsigHoras.Properties as TcxSpinEditProperties) do
  begin
    MinValue := 0.5;
    MaxValue := 999;
    Increment := 0.5;
    ValueType := vtFloat;
  end;

  // Checkbox "Solo capacitados" sobre el grid de disponibles
  FchkSoloCapacitados := TCheckBox.Create(Self);
  FchkSoloCapacitados.Parent := pnlDisponibles;
  FchkSoloCapacitados.SetBounds(pnlDisponibles.Width - 130, 3, 125, 17);
  FchkSoloCapacitados.Anchors := [akTop, akRight];
  FchkSoloCapacitados.Caption := 'Solo capacitados';
  FchkSoloCapacitados.Checked := True;
  FchkSoloCapacitados.Font.Name := 'Segoe UI';
  FchkSoloCapacitados.Font.Size := 8;
  FchkSoloCapacitados.OnClick := SoloCapacitadosClick;
end;

procedure TfrmAssignOperaris.FormDestroy(Sender: TObject);
begin
  //
end;

procedure TfrmAssignOperaris.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

{ --- Carregar dades als grids --- }

procedure TfrmAssignOperaris.LoadGrids;
begin
  LoadAssignats;
  LoadDisponibles;
end;

procedure TfrmAssignOperaris.LoadAssignats;
var
  Ops: TArray<TOperario>;
  I, Row: Integer;
  Horas: Double;
begin
  tvAssignats.BeginUpdate;
  try
    tvAssignats.DataController.RecordCount := 0;
    Ops := FRepo.GetOperarisAssignatsAlNode(FDataId);
    tvAssignats.DataController.RecordCount := Length(Ops);
    for I := 0 to High(Ops) do
    begin
      Row := I;
      Horas := FRepo.GetHoresOperariEnNode(Ops[I].Id, FDataId);
      tvAssignats.DataController.Values[Row, colAsigId.Index] := Ops[I].Id;
      tvAssignats.DataController.Values[Row, colAsigNombre.Index] := Ops[I].Nombre;
      tvAssignats.DataController.Values[Row, colAsigHoras.Index] := Horas;
      tvAssignats.DataController.Values[Row, colAsigCapacitats.Index] := CapacitacionsStr(Ops[I].Id);
    end;
  finally
    tvAssignats.EndUpdate;
  end;
end;

procedure TfrmAssignOperaris.LoadDisponibles;
var
  AllOps, Ops: TArray<TOperario>;
  Assigned: TDictionary<Integer, Boolean>;
  Asigs: TArray<TAsignacionOperario>;
  List: TList<TOperario>;
  I, Row: Integer;
begin
  if FchkSoloCapacitados.Checked and (FOperacion <> '') then
    Ops := FRepo.GetOperarisDisponiblesPerNode(FDataId, FOperacion)
  else
  begin
    // Todos los operarios no asignados al nodo principal
    AllOps := FRepo.GetOperarios;
    Asigs := FRepo.GetAsignacionsByNode(FDataId);
    Assigned := TDictionary<Integer, Boolean>.Create;
    List := TList<TOperario>.Create;
    try
      for I := 0 to High(Asigs) do
        Assigned.AddOrSetValue(Asigs[I].OperarioId, True);
      for I := 0 to High(AllOps) do
        if not Assigned.ContainsKey(AllOps[I].Id) then
          List.Add(AllOps[I]);
      Ops := List.ToArray;
    finally
      Assigned.Free;
      List.Free;
    end;
  end;

  tvDisponibles.BeginUpdate;
  try
    tvDisponibles.DataController.RecordCount := 0;
    tvDisponibles.DataController.RecordCount := Length(Ops);
    for I := 0 to High(Ops) do
    begin
      Row := I;
      tvDisponibles.DataController.Values[Row, colDispId.Index] := Ops[I].Id;
      tvDisponibles.DataController.Values[Row, colDispNombre.Index] := Ops[I].Nombre;
      tvDisponibles.DataController.Values[Row, colDispCalendario.Index] := Ops[I].Calendario;
      tvDisponibles.DataController.Values[Row, colDispCapacitats.Index] := CapacitacionsStr(Ops[I].Id);
    end;
  finally
    tvDisponibles.EndUpdate;
  end;
end;

procedure TfrmAssignOperaris.SoloCapacitadosClick(Sender: TObject);
begin
  LoadDisponibles;
end;

procedure TfrmAssignOperaris.UpdateResumen;
var
  N: Integer;
begin
  N := FRepo.CountAssignatsAlNode(FDataId);
  FResultAssignats := N;
  lblResumen.Caption := Format('Asignados: %d / %d necesarios  |  Duración nodo: %.1f min',
    [N, FOperariosNecesarios, FDurationMin]);

  if N < FOperariosNecesarios then
    lblResumen.Font.Color := clRed
  else if N = FOperariosNecesarios then
    lblResumen.Font.Color := $00008000  // verd fosc
  else
    lblResumen.Font.Color := $000080FF; // taronja
end;

{ --- Accions assignar/desassignar --- }

procedure TfrmAssignOperaris.DoAssignar(Sender: TObject);
var
  RecIdx: Integer;
  OpId: Integer;
  A: TAsignacionOperario;
  DefaultHoras: Double;
  I: Integer;
begin
  RecIdx := tvDisponibles.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  OpId := tvDisponibles.DataController.Values[RecIdx, colDispId.Index];

  DefaultHoras := FDurationMin / 60;
  if DefaultHoras < 0.5 then
    DefaultHoras := 0.5;

  // Asignar a todos los DataIds
  A.OperarioId := OpId;
  for I := 0 to High(FDataIds) do
  begin
    A.DataId := FDataIds[I];
    A.Horas := DefaultHoras;
    FRepo.AddAsignacion(A);
  end;

  LoadGrids;
  UpdateResumen;
end;

procedure TfrmAssignOperaris.DoDesassignar(Sender: TObject);
var
  RecIdx: Integer;
  OpId: Integer;
  I: Integer;
begin
  RecIdx := tvAssignats.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  OpId := tvAssignats.DataController.Values[RecIdx, colAsigId.Index];

  // Desasignar de todos los DataIds
  for I := 0 to High(FDataIds) do
    FRepo.RemoveAsignacion(OpId, FDataIds[I]);

  LoadGrids;
  UpdateResumen;
end;

procedure TfrmAssignOperaris.DoHorasEditValueChanged(Sender: TObject);
var
  RecIdx: Integer;
  OpId: Integer;
  V: Variant;
  Horas: Double;
begin
  RecIdx := tvAssignats.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  OpId := tvAssignats.DataController.Values[RecIdx, colAsigId.Index];
  V := tvAssignats.DataController.Values[RecIdx, colAsigHoras.Index];
  if VarIsNull(V) then Exit;
  Horas := V;

  FRepo.UpdateAsignacionHoras(OpId, FDataId, Horas);
end;

{ --- Helpers --- }

function TfrmAssignOperaris.CapacitacionsStr(OperarioId: Integer): string;
var
  Caps: TArray<string>;
  I: Integer;
begin
  Caps := FRepo.GetCapacitacionsByOperario(OperarioId);
  Result := '';
  for I := 0 to High(Caps) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Caps[I];
  end;
end;

{ --- Visual --- }

procedure TfrmAssignOperaris.chkDarkModeClick(Sender: TObject);
begin
  ApplyDarkMode(chkDarkMode.Checked);
end;

procedure TfrmAssignOperaris.ApplyDarkMode(ADark: Boolean);
const
  DARK_BG     = $00302C28;
  DARK_HEADER = $003C3836;
  DARK_TEXT   = $00F0F0F0;
  DARK_SUB    = $00A0A0A0;
  DARK_LINE   = $00504840;
begin
  if ADark then
  begin
    LookAndFeel.SkinName := 'Office2019Black';
    pnlHeader.Color := DARK_HEADER;
    lblTitle.Font.Color := DARK_TEXT;
    lblSubtitle.Font.Color := DARK_SUB;
    shpHeaderLine.Brush.Color := DARK_LINE;
    chkDarkMode.Font.Color := DARK_TEXT;
    pnlBottom.Color := DARK_HEADER;
    pnlContent.Color := DARK_BG;
    pnlAssignats.Color := DARK_BG;
    pnlDisponibles.Color := DARK_BG;
    lblAssignats.Font.Color := DARK_TEXT;
    lblDisponibles.Font.Color := DARK_TEXT;
    Color := DARK_BG;
  end
  else
  begin
    LookAndFeel.SkinName := 'Office2019Colorful';
    pnlHeader.Color := clWhite;
    lblTitle.Font.Color := 4474440;
    lblSubtitle.Font.Color := clGray;
    shpHeaderLine.Brush.Color := 15061727;
    chkDarkMode.Font.Color := clWindowText;
    pnlBottom.Color := clBtnFace;
    pnlContent.Color := clBtnFace;
    pnlAssignats.Color := clBtnFace;
    pnlDisponibles.Color := clBtnFace;
    lblAssignats.Font.Color := 4474440;
    lblDisponibles.Font.Color := 4474440;
    Color := clBtnFace;
  end;
end;

{ --- Botons --- }

procedure TfrmAssignOperaris.btnOKClick(Sender: TObject);
begin
  FResultAssignats := FRepo.CountAssignatsAlNode(FDataId);
  ModalResult := mrOk;
end;

procedure TfrmAssignOperaris.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
