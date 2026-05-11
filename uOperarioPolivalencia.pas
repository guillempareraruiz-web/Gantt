unit uOperarioPolivalencia;

{
  TfrmOperarioPolivalencia - editor de:
    - Habilidades del operario (codigo + nivel + factor eficiencia).
    - Coste laboral (sueldo eur/hora + recargo nocturno + recargo festivo).

  Recibe el OperatorId y persiste:
    - Habilidades via THabilidadRepo (in-memory v1; SQL en cableo BD).
    - Sueldo y recargos directamente en FS_PL_Operator via DMPlanner.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxButtons,
  Data.Win.ADODB, Data.DB,
  uOperariosTypes, uOperariosRepo, uPlanProdTypes, uHabilidadRepo;

type
  TfrmOperarioPolivalencia = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlCoste: TPanel;
    lblCoste: TLabel;
    lblSueldo: TLabel;
    edSueldoEurHora: TEdit;
    lblRecargoNoche: TLabel;
    edRecargoNoche: TEdit;
    lblRecargoFestivo: TLabel;
    edRecargoFestivo: TEdit;
    btnGuardarCoste: TcxButton;
    pnlActions: TPanel;
    lblHabilidades: TLabel;
    btnAdd: TcxButton;
    btnEdit: TcxButton;
    btnRemove: TcxButton;
    grdHabs: TcxGrid;
    tvHabs: TcxGridTableView;
    colH_Cod: TcxGridColumn;
    colH_Desc: TcxGridColumn;
    colH_Nivel: TcxGridColumn;
    colH_Factor: TcxGridColumn;
    lvHabs: TcxGridLevel;
    pnlBottom: TPanel;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnGuardarCosteClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure tvHabsDblClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FOpRepo: TOperariosRepo;
    FHabRepo: THabilidadRepo;
    FOperarioId: Integer;
    FOperarioNombre: string;
    FRows: TArray<TOperarioHabilidad>;
    procedure LoadCoste;
    procedure RefreshGrid;
    function CurrentRowIdx: Integer;
    function ParseDouble(const S: string; ADefault: Double): Double;
  public
    class procedure Execute(AOpRepo: TOperariosRepo; AHabRepo: THabilidadRepo;
      AOperarioId: Integer; const AOperarioNombre: string);
  end;

implementation

uses
  uHabilidadPicker, uDMPlanner;

{$R *.dfm}

class procedure TfrmOperarioPolivalencia.Execute(AOpRepo: TOperariosRepo;
  AHabRepo: THabilidadRepo; AOperarioId: Integer;
  const AOperarioNombre: string);
var
  F: TfrmOperarioPolivalencia;
begin
  if not Assigned(AOpRepo) or not Assigned(AHabRepo) then Exit;
  if AOperarioId <= 0 then Exit;
  F := TfrmOperarioPolivalencia.Create(nil);
  try
    F.FOpRepo := AOpRepo;
    F.FHabRepo := AHabRepo;
    F.FOperarioId := AOperarioId;
    F.FOperarioNombre := AOperarioNombre;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmOperarioPolivalencia.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  tvHabs.OptionsBehavior.IncSearch := True;
  tvHabs.OptionsCustomize.ColumnsQuickCustomization := True;
  tvHabs.OptionsData.Editing := False;
  tvHabs.OptionsSelection.CellSelect := False;
  tvHabs.OptionsView.Indicator := True;
  tvHabs.OptionsView.GroupByBox := False;
end;

procedure TfrmOperarioPolivalencia.FormShow(Sender: TObject);
begin
  lblTitle.Caption := Format('Polivalencia y coste - %s', [FOperarioNombre]);
  LoadCoste;
  RefreshGrid;
end;

function TfrmOperarioPolivalencia.ParseDouble(const S: string;
  ADefault: Double): Double;
var
  T: string;
begin
  T := StringReplace(Trim(S), ',', '.', [rfReplaceAll]);
  Result := StrToFloatDef(T, ADefault, TFormatSettings.Invariant);
end;

procedure TfrmOperarioPolivalencia.LoadCoste;
var
  Q: TADOQuery;
  Sueldo, RecNoche, RecFest: Double;
begin
  Sueldo := 0;
  RecNoche := 1;
  RecFest := 1;
  if Assigned(DMPlanner) and Assigned(DMPlanner.ADOConnection) then
  begin
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT ISNULL(SueldoEurHora, 0) AS S, ' +
        '       ISNULL(RecargoTurnoNoche, 1) AS RN, ' +
        '       ISNULL(RecargoFestivo, 1) AS RF ' +
        'FROM FS_PL_Operator ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        '  AND OperatorId = ' + IntToStr(FOperarioId);
      try
        Q.Open;
        if not Q.Eof then
        begin
          Sueldo := Q.FieldByName('S').AsFloat;
          RecNoche := Q.FieldByName('RN').AsFloat;
          RecFest := Q.FieldByName('RF').AsFloat;
        end;
      except
        // Si V020 no aplicada todavia o BD no disponible, usa defaults
      end;
    finally
      Q.Free;
    end;
  end;
  edSueldoEurHora.Text := FormatFloat('0.00', Sueldo);
  edRecargoNoche.Text := FormatFloat('0.0000', RecNoche);
  edRecargoFestivo.Text := FormatFloat('0.0000', RecFest);
end;

procedure TfrmOperarioPolivalencia.btnGuardarCosteClick(Sender: TObject);
var
  Cmd: TADOCommand;
  Sueldo, RecNoche, RecFest: Double;
  Affected: Integer;
begin
  Sueldo := ParseDouble(edSueldoEurHora.Text, 0);
  RecNoche := ParseDouble(edRecargoNoche.Text, 1);
  RecFest := ParseDouble(edRecargoFestivo.Text, 1);
  if not Assigned(DMPlanner) or not Assigned(DMPlanner.ADOConnection) then
  begin
    MessageDlg('No hay conexi'#243'n a base de datos.', mtError, [mbOK], 0);
    Exit;
  end;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := Format(
      'UPDATE FS_PL_Operator SET SueldoEurHora = %s, ' +
      'RecargoTurnoNoche = %s, RecargoFestivo = %s ' +
      'WHERE CodigoEmpresa = %d AND OperatorId = %d',
      [FloatToStr(Sueldo, TFormatSettings.Invariant),
       FloatToStr(RecNoche, TFormatSettings.Invariant),
       FloatToStr(RecFest, TFormatSettings.Invariant),
       DMPlanner.CodigoEmpresa, FOperarioId]);
    try
      Cmd.Execute(Affected, EmptyParam);
      ShowMessage('Coste guardado correctamente.');
    except
      on E: Exception do
        MessageDlg('Error guardando coste: ' + E.Message, mtError, [mbOK], 0);
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmOperarioPolivalencia.RefreshGrid;
var
  I: Integer;
  H: THabilidad;
  Desc: string;
begin
  FRows := FHabRepo.GetHabilidadesOperario(FOperarioId);
  lblHabilidades.Caption := Format('Habilidades del operario (%d)',
    [Length(FRows)]);
  tvHabs.BeginUpdate;
  try
    tvHabs.DataController.RecordCount := 0;
    tvHabs.DataController.RecordCount := Length(FRows);
    for I := 0 to High(FRows) do
    begin
      tvHabs.DataController.Values[I, colH_Cod.Index] :=
        FRows[I].CodHabilidad;
      Desc := '';
      if FHabRepo.GetHabilidad(FRows[I].CodHabilidad, H) then
        Desc := H.Descripcion;
      tvHabs.DataController.Values[I, colH_Desc.Index] := Desc;
      tvHabs.DataController.Values[I, colH_Nivel.Index] :=
        Format('%s (%d)',
          [NivelSkillToStr(FRows[I].Nivel), Ord(FRows[I].Nivel)]);
      tvHabs.DataController.Values[I, colH_Factor.Index] :=
        FormatFloat('0.0000', FRows[I].FactorEficiencia);
    end;
  finally
    tvHabs.EndUpdate;
  end;
end;

function TfrmOperarioPolivalencia.CurrentRowIdx: Integer;
begin
  Result := tvHabs.DataController.FocusedRecordIndex;
  if (Result < 0) or (Result > High(FRows)) then Result := -1;
end;

procedure TfrmOperarioPolivalencia.btnAddClick(Sender: TObject);
var
  CodSel: string;
  Nivel: TNivelSkill;
  I: Integer;
  Excluir: TArray<string>;
begin
  SetLength(Excluir, Length(FRows));
  for I := 0 to High(FRows) do
    Excluir[I] := FRows[I].CodHabilidad;
  if not TfrmHabilidadPicker.Execute(FHabRepo,
    Format('A'#241'adir habilidad a %s', [FOperarioNombre]),
    CodSel, Nivel, Excluir) then Exit;
  FHabRepo.SetOperarioHabilidad(FOperarioId, CodSel, Nivel, 1.0);
  RefreshGrid;
end;

procedure TfrmOperarioPolivalencia.btnEditClick(Sender: TObject);
var
  Idx, NuevoIdx: Integer;
  NivelStr: string;
  FactorStr: string;
  Factor: Double;
begin
  Idx := CurrentRowIdx;
  if Idx < 0 then Exit;
  NivelStr := IntToStr(Ord(FRows[Idx].Nivel));
  if not InputQuery('Cambiar nivel',
    Format('%s'#13#10'0=Aprendiz, 1=Junior, 2=Senior, 3=Experto',
      [FRows[Idx].CodHabilidad]),
    NivelStr) then Exit;
  NuevoIdx := StrToIntDef(NivelStr, -1);
  if NuevoIdx < 0 then NuevoIdx := 0
  else if NuevoIdx > 3 then NuevoIdx := 3;

  FactorStr := FormatFloat('0.0000', FRows[Idx].FactorEficiencia);
  if not InputQuery('Factor eficiencia',
    'Factor (1.0 = est'#225'ndar; <1 m'#225's r'#225'pido; >1 m'#225's lento):',
    FactorStr) then Exit;
  Factor := ParseDouble(FactorStr, 1.0);
  if Factor <= 0 then Factor := 1.0;

  FHabRepo.SetOperarioHabilidad(FOperarioId, FRows[Idx].CodHabilidad,
    TNivelSkill(NuevoIdx), Factor);
  RefreshGrid;
end;

procedure TfrmOperarioPolivalencia.btnRemoveClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CurrentRowIdx;
  if Idx < 0 then Exit;
  if MessageDlg(Format('?Quitar habilidad %s del operario?',
       [FRows[Idx].CodHabilidad]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FHabRepo.RemoveOperarioHabilidad(FOperarioId, FRows[Idx].CodHabilidad);
  RefreshGrid;
end;

procedure TfrmOperarioPolivalencia.tvHabsDblClick(Sender: TObject);
begin
  btnEditClick(nil);
end;

procedure TfrmOperarioPolivalencia.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
