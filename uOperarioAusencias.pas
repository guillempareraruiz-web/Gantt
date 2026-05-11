unit uOperarioAusencias;

{
  TfrmOperarioAusencias - CRUD de ausencias por operario.

  Layout:
    - Izquierda (panel 240 px): cerca + filtros + listado de operarios.
    - Derecha (cxPageControl): pestana "Lista" (cxGrid) + pestana "Calendario"
      (control mensual custom-paint).

  Persistencia: TOperatorAbsencesRepo (in-memory; en v2 SQL).

  Validacion: al guardar comprueba solapamientos con otras ausencias del
  mismo operario y ofrece opcion "Forzar".

  Apertura: TfrmOperarioAusencias.Execute(AOpRepo, AAbsRepo, AOperarioId).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.DateUtils, System.Math, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxButtons,
  uOperariosTypes, uOperariosRepo, uOperatorAbsencesRepo, dxSkinBasic,
  dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee,
  dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;

type
  // Control mensual custom-paint para visualizar ausencias.
  TCalendarioAusenciasControl = class(TCustomControl)
  private
    FAusencias: TArray<TAusencia>;
    FYear: Word;
    FMonth: Word;
    FOnDayClick: TNotifyEvent;
    FClickedDate: TDateTime;
    FHoveredDate: TDateTime;
    function CellRectAt(R, C: Integer; const Area: TRect): TRect;
    function DateAtPoint(X, Y: Integer): TDateTime;
    function FindAusenciaAt(const ADate: TDateTime;
      out Aus: TAusencia): Boolean;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetMonth(AYear, AMonth: Word);
    procedure SetAusencias(const A: TArray<TAusencia>);
    procedure StepMonth(Delta: Integer);
    property Year: Word read FYear;
    property Month: Word read FMonth;
    property ClickedDate: TDateTime read FClickedDate;
    property OnDayClick: TNotifyEvent read FOnDayClick write FOnDayClick;
  end;

  TfrmOperarioAusencias = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlLeft: TPanel;
    edBuscar: TEdit;
    cbFiltroDepto: TComboBox;
    grdOperarios: TcxGrid;
    tvOperarios: TcxGridTableView;
    colOpNombre: TcxGridColumn;
    colOpTotal: TcxGridColumn;
    colOpFiltro: TcxGridColumn;
    lvOperarios: TcxGridLevel;
    pnlMain: TPanel;
    pcMain: TPageControl;
    tsLista: TTabSheet;
    tsCalendario: TTabSheet;
    pnlListaTop: TPanel;
    btnNueva: TcxButton;
    btnEditar: TcxButton;
    btnEliminar: TcxButton;
    btnDuplicar: TcxButton;
    cbFiltroAno: TComboBox;
    cbFiltroTipo: TComboBox;
    btnExportarCsv: TcxButton;
    grdAusencias: TcxGrid;
    tvAusencias: TcxGridTableView;
    colTipo: TcxGridColumn;
    colInicio: TcxGridColumn;
    colFin: TcxGridColumn;
    colDias: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    lvAusencias: TcxGridLevel;
    pnlCalTop: TPanel;
    btnPrevMes: TcxButton;
    btnNextMes: TcxButton;
    btnHoyCal: TcxButton;
    lblMesAno: TLabel;
    pnlCalHost: TPanel;
    lblLegendaCal: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TcxButton;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edBuscarChange(Sender: TObject);
    procedure cbFiltroDeptoChange(Sender: TObject);
    procedure tvOperariosFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure btnNuevaClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure btnDuplicarClick(Sender: TObject);
    procedure btnExportarCsvClick(Sender: TObject);
    procedure cbFiltroAnoChange(Sender: TObject);
    procedure cbFiltroTipoChange(Sender: TObject);
    procedure tvAusenciasDblClick(Sender: TObject);
    procedure tvAusenciasCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
    procedure btnPrevMesClick(Sender: TObject);
    procedure btnNextMesClick(Sender: TObject);
    procedure btnHoyCalClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FOpRepo: TOperariosRepo;
    FAbsRepo: TOperatorAbsencesRepo;
    FCurrentOpId: Integer;
    FCurrentRows: TArray<TAusencia>;
    FCalendario: TCalendarioAusenciasControl;
    FOperarioRowIds: TArray<Integer>;  // mapping fila grid -> OperarioId
    procedure LoadOperarios;
    procedure LoadDepartamentos;
    procedure LoadAnios;
    procedure ApplyFilterOperarios;
    procedure SelectOperarioInList(OpId: Integer);
    function CurrentOperarioNombre: string;
    function CountAusenciasFiltro(OpId: Integer): Integer;
    procedure RefreshAusencias;
    procedure RefreshGrid;
    procedure RefreshCalendario;
    procedure UpdateMesAnoLabel;
    procedure CalendarioOnDayClick(Sender: TObject);
    function HasOverlap(const A: TAusencia; out OtherDesc: string): Boolean;
    function ConfirmOverlap(const OtherDesc: string): Boolean;
    procedure DoEditAusencia(var A: TAusencia; IsNew: Boolean);
  public
    class procedure Execute(AOpRepo: TOperariosRepo;
      AAbsRepo: TOperatorAbsencesRepo; AOperarioInicialId: Integer = 0);
  end;

implementation

uses
  uAusenciaEdit;

{$R *.dfm}

{ ============== TCalendarioAusenciasControl ============== }

constructor TCalendarioAusenciasControl.Create(AOwner: TComponent);
var
  D: Word;
begin
  inherited;
  DoubleBuffered := True;
  ControlStyle := ControlStyle + [csOpaque];
  DecodeDate(Now, FYear, FMonth, D);
  FClickedDate := 0;
  FHoveredDate := 0;
  Color := clWhite;
end;

procedure TCalendarioAusenciasControl.SetMonth(AYear, AMonth: Word);
begin
  FYear := AYear;
  FMonth := AMonth;
  Invalidate;
end;

procedure TCalendarioAusenciasControl.SetAusencias(const A: TArray<TAusencia>);
begin
  FAusencias := A;
  Invalidate;
end;

procedure TCalendarioAusenciasControl.StepMonth(Delta: Integer);
var
  D: TDateTime;
begin
  D := IncMonth(EncodeDate(FYear, FMonth, 1), Delta);
  FYear := YearOf(D);
  FMonth := MonthOf(D);
  Invalidate;
end;

function TCalendarioAusenciasControl.CellRectAt(R, C: Integer;
  const Area: TRect): TRect;
var
  W, H: Integer;
begin
  W := (Area.Right - Area.Left) div 7;
  H := (Area.Bottom - Area.Top) div 6;
  Result.Left := Area.Left + C * W;
  Result.Top := Area.Top + R * H;
  Result.Right := Result.Left + W;
  Result.Bottom := Result.Top + H;
end;

function TCalendarioAusenciasControl.DateAtPoint(X, Y: Integer): TDateTime;
var
  HeaderH, GridY: Integer;
  Area: TRect;
  W, H, Col, Row: Integer;
  FirstDay: TDateTime;
  FirstDow, Day, DaysInMonth: Integer;
begin
  Result := 0;
  HeaderH := 64;
  GridY := HeaderH;
  if Y < GridY then Exit;

  Area := Rect(0, GridY, ClientWidth, ClientHeight);
  W := (Area.Right - Area.Left) div 7;
  H := (Area.Bottom - Area.Top) div 6;
  if (W <= 0) or (H <= 0) then Exit;

  Col := (X - Area.Left) div W;
  Row := (Y - Area.Top) div H;
  if (Col < 0) or (Col > 6) or (Row < 0) or (Row > 5) then Exit;

  FirstDay := EncodeDate(FYear, FMonth, 1);
  FirstDow := DayOfTheWeek(FirstDay) - 1;  // 0 = lunes
  Day := Row * 7 + Col - FirstDow + 1;
  DaysInMonth := DaysInAMonth(FYear, FMonth);
  if (Day < 1) or (Day > DaysInMonth) then Exit;

  Result := EncodeDate(FYear, FMonth, Day);
end;

function TCalendarioAusenciasControl.FindAusenciaAt(const ADate: TDateTime;
  out Aus: TAusencia): Boolean;
var
  I: Integer;
  D: TDateTime;
begin
  Result := False;
  D := DateOf(ADate);
  for I := 0 to High(FAusencias) do
  begin
    if FAusencias[I].EsHoraria then
    begin
      // Horario: solo el d'ia exacto del tramo
      if DateOf(FAusencias[I].FechaInicio) = D then
      begin
        Aus := FAusencias[I];
        Exit(True);
      end;
    end
    else
    begin
      // D'ia(s) completo(s): rango [Inicio, Fin)
      if (D >= DateOf(FAusencias[I].FechaInicio)) and
         (D < DateOf(FAusencias[I].FechaFin)) then
      begin
        Aus := FAusencias[I];
        Exit(True);
      end;
    end;
  end;
end;

procedure TCalendarioAusenciasControl.Paint;
const
  DiasSem: array[0..6] of string = ('Lun', 'Mar', 'Mi'#233, 'Jue', 'Vie', 'S'#225'b', 'Dom');
var
  HeaderH, I, Col, Row: Integer;
  Area, R: TRect;
  FirstDay, ADate: TDateTime;
  FirstDow, Day, DaysInMonth: Integer;
  Aus: TAusencia;
  Hoy: TDateTime;
  S: string;
begin
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ClientRect);

  HeaderH := 64;

  // Cabecera mes/a'no (solo titulo de la fila de dias de semana)
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := 'Segoe UI Semibold';
  Canvas.Font.Size := 9;
  Canvas.Font.Color := $00606060;
  Canvas.Font.Quality := fqClearTypeNatural;

  Area := Rect(0, HeaderH - 24, ClientWidth, HeaderH);
  for I := 0 to 6 do
  begin
    R := CellRectAt(0, I, Rect(0, Area.Top, ClientWidth, Area.Bottom));
    R.Bottom := Area.Bottom;
    DrawText(Canvas.Handle, PChar(DiasSem[I]), -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;

  // Linea separadora bajo cabecera
  Canvas.Pen.Color := $00D0D0D0;
  Canvas.MoveTo(0, HeaderH - 1);
  Canvas.LineTo(ClientWidth, HeaderH - 1);

  // Grid de dias
  Area := Rect(0, HeaderH, ClientWidth, ClientHeight);
  FirstDay := EncodeDate(FYear, FMonth, 1);
  FirstDow := DayOfTheWeek(FirstDay) - 1;  // 0 = lunes
  DaysInMonth := DaysInAMonth(FYear, FMonth);
  Hoy := Trunc(Now);

  for Row := 0 to 5 do
    for Col := 0 to 6 do
    begin
      R := CellRectAt(Row, Col, Area);
      Day := Row * 7 + Col - FirstDow + 1;

      // Fondo
      if (Day < 1) or (Day > DaysInMonth) then
      begin
        Canvas.Brush.Color := $00F4F4F0;
        Canvas.FillRect(R);
      end
      else
      begin
        ADate := EncodeDate(FYear, FMonth, Day);

        // Fondo base
        if ADate = Hoy then
          Canvas.Brush.Color := $00FFF4E5
        else if Col >= 5 then
          Canvas.Brush.Color := $00FAFAF8
        else
          Canvas.Brush.Color := clWhite;
        Canvas.FillRect(R);

        // Si hay ausencia, pintar overlay
        if FindAusenciaAt(ADate, Aus) then
        begin
          if Aus.EsHoraria then
          begin
            // Franja superior delgada (no ocupa la celda entera)
            Canvas.Brush.Color := TipoAusenciaColor(Aus.Tipo);
            Canvas.FillRect(Rect(R.Left, R.Top, R.Right, R.Top + 6));
          end
          else
          begin
            Canvas.Brush.Color := TipoAusenciaColor(Aus.Tipo);
            Canvas.FillRect(R);
          end;
        end;

        // Numero de dia
        Canvas.Brush.Style := bsClear;
        Canvas.Font.Name := 'Segoe UI';
        if ADate = Hoy then
        begin
          Canvas.Font.Style := [fsBold];
          Canvas.Font.Color := $002080F0;
        end
        else
        begin
          Canvas.Font.Style := [];
          Canvas.Font.Color := $00404040;
        end;
        Canvas.Font.Size := 10;
        S := IntToStr(Day);
        Canvas.TextOut(R.Left + 6, R.Top + 4, S);

        // Etiqueta tipo si hay ausencia (esquina inf)
        if FindAusenciaAt(ADate, Aus) then
        begin
          Canvas.Font.Style := [fsBold];
          Canvas.Font.Size := 7;
          Canvas.Font.Color := $00303030;
          if Aus.EsHoraria then
            S := Format('%s %.1fh',
              [TipoAusenciaToStr(Aus.Tipo),
               (Aus.FechaFin - Aus.FechaInicio) * 24])
          else
            S := TipoAusenciaToStr(Aus.Tipo);
          Canvas.TextOut(R.Left + 6, R.Bottom - 16, S);
        end;

        // Hover
        if ADate = FHoveredDate then
        begin
          Canvas.Pen.Color := $00B86848;
          Canvas.Pen.Width := 2;
          Canvas.Brush.Style := bsClear;
          Canvas.Rectangle(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1);
          Canvas.Pen.Width := 1;
        end;
      end;

      // Borde celda
      Canvas.Pen.Color := $00E0E0E0;
      Canvas.Pen.Width := 1;
      Canvas.Brush.Style := bsClear;
      Canvas.MoveTo(R.Right - 1, R.Top);
      Canvas.LineTo(R.Right - 1, R.Bottom);
      Canvas.MoveTo(R.Left, R.Bottom - 1);
      Canvas.LineTo(R.Right, R.Bottom - 1);
    end;
end;

procedure TCalendarioAusenciasControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  D: TDateTime;
begin
  inherited;
  if Button <> mbLeft then Exit;
  D := DateAtPoint(X, Y);
  if D > 0 then
  begin
    FClickedDate := D;
    if Assigned(FOnDayClick) then FOnDayClick(Self);
  end;
end;

procedure TCalendarioAusenciasControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  D: TDateTime;
begin
  inherited;
  D := DateAtPoint(X, Y);
  if D <> FHoveredDate then
  begin
    FHoveredDate := D;
    Invalidate;
  end;
end;

procedure TCalendarioAusenciasControl.CMMouseLeave(var Msg: TMessage);
begin
  if FHoveredDate <> 0 then
  begin
    FHoveredDate := 0;
    Invalidate;
  end;
end;

{ ============== TfrmOperarioAusencias ============== }

class procedure TfrmOperarioAusencias.Execute(AOpRepo: TOperariosRepo;
  AAbsRepo: TOperatorAbsencesRepo; AOperarioInicialId: Integer);
var
  F: TfrmOperarioAusencias;
begin
  if not Assigned(AOpRepo) or not Assigned(AAbsRepo) then Exit;
  F := TfrmOperarioAusencias.Create(nil);
  try
    F.FOpRepo := AOpRepo;
    F.FAbsRepo := AAbsRepo;
    F.FCurrentOpId := AOperarioInicialId;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmOperarioAusencias.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  pcMain.ActivePageIndex := 0;

  // cxGrid styling
  tvAusencias.OptionsBehavior.IncSearch := True;
  tvAusencias.OptionsCustomize.ColumnsQuickCustomization := True;
  tvAusencias.OptionsData.Editing := False;
  tvAusencias.OptionsData.Inserting := False;
  tvAusencias.OptionsData.Deleting := False;
  tvAusencias.OptionsSelection.CellSelect := False;
  tvAusencias.OptionsSelection.MultiSelect := False;
  tvAusencias.OptionsView.Indicator := True;

  // Calendario
  FCalendario := TCalendarioAusenciasControl.Create(Self);
  FCalendario.Parent := pnlCalHost;
  FCalendario.Align := alClient;
  FCalendario.OnDayClick := CalendarioOnDayClick;
end;

procedure TfrmOperarioAusencias.FormDestroy(Sender: TObject);
begin
  // FCalendario es Owner-managed
end;

procedure TfrmOperarioAusencias.FormShow(Sender: TObject);
var
  Y, M, D: Word;
begin
  LoadDepartamentos;
  LoadAnios;
  LoadOperarios;

  // Filtro tipo
  cbFiltroTipo.Items.Clear;
  cbFiltroTipo.Items.Add('(todos)');
  cbFiltroTipo.Items.Add(TipoAusenciaToStr(taVacaciones));
  cbFiltroTipo.Items.Add(TipoAusenciaToStr(taBaja));
  cbFiltroTipo.Items.Add(TipoAusenciaToStr(taFormacion));
  cbFiltroTipo.Items.Add(TipoAusenciaToStr(taPermiso));
  cbFiltroTipo.Items.Add(TipoAusenciaToStr(taOtros));
  cbFiltroTipo.ItemIndex := 0;

  if FCurrentOpId > 0 then
    SelectOperarioInList(FCurrentOpId)
  else if Length(FOperarioRowIds) > 0 then
  begin
    tvOperarios.DataController.FocusedRecordIndex := 0;
    FCurrentOpId := FOperarioRowIds[0];
    RefreshAusencias;
  end;

  DecodeDate(Now, Y, M, D);
  FCalendario.SetMonth(Y, M);
  UpdateMesAnoLabel;
  RefreshAusencias;
end;

procedure TfrmOperarioAusencias.LoadDepartamentos;
var
  Deptos: TArray<TDepartamento>;
  I: Integer;
begin
  cbFiltroDepto.Items.BeginUpdate;
  try
    cbFiltroDepto.Items.Clear;
    cbFiltroDepto.Items.AddObject('(todos)', TObject(0));
    Deptos := FOpRepo.GetDepartamentos;
    for I := 0 to High(Deptos) do
      cbFiltroDepto.Items.AddObject(Deptos[I].Nombre, TObject(Deptos[I].Id));
  finally
    cbFiltroDepto.Items.EndUpdate;
  end;
  cbFiltroDepto.ItemIndex := 0;
end;

procedure TfrmOperarioAusencias.LoadAnios;
var
  Y: Word;
  CurrentY: Integer;
begin
  Y := YearOf(Now);
  CurrentY := Y;
  cbFiltroAno.Items.Clear;
  cbFiltroAno.Items.Add('(todos)');
  cbFiltroAno.Items.Add(IntToStr(CurrentY - 1));
  cbFiltroAno.Items.Add(IntToStr(CurrentY));
  cbFiltroAno.Items.Add(IntToStr(CurrentY + 1));
  cbFiltroAno.ItemIndex := 2;  // a'no actual por defecto
end;

procedure TfrmOperarioAusencias.LoadOperarios;
begin
  ApplyFilterOperarios;
end;

procedure TfrmOperarioAusencias.ApplyFilterOperarios;
var
  Ops: TArray<TOperario>;
  Deptos: TArray<TDepartamento>;
  I, K, DeptoId: Integer;
  Filtro: string;
  PrevId: Integer;
  Op: TOperario;
  IncluirOp: Boolean;
  Visibles: TList<TOperario>;
  RowIdx: Integer;
  TotalAbs: Integer;
begin
  PrevId := FCurrentOpId;
  Filtro := AnsiLowerCase(Trim(edBuscar.Text));
  DeptoId := 0;
  if (cbFiltroDepto.ItemIndex > 0) and
     (cbFiltroDepto.Items.Count > cbFiltroDepto.ItemIndex) then
    DeptoId := Integer(cbFiltroDepto.Items.Objects[cbFiltroDepto.ItemIndex]);

  Visibles := TList<TOperario>.Create;
  try
    Ops := FOpRepo.GetOperarios;
    for I := 0 to High(Ops) do
    begin
      Op := Ops[I];
      IncluirOp := True;
      if (Filtro <> '') and (Pos(Filtro, AnsiLowerCase(Op.Nombre)) = 0) then
        IncluirOp := False;
      if IncluirOp and (DeptoId > 0) then
      begin
        IncluirOp := False;
        Deptos := FOpRepo.GetDeptsByOperario(Op.Id);
        for K := 0 to High(Deptos) do
          if Deptos[K].Id = DeptoId then
          begin
            IncluirOp := True;
            Break;
          end;
      end;
      if IncluirOp then
        Visibles.Add(Op);
    end;

    SetLength(FOperarioRowIds, Visibles.Count);
    tvOperarios.BeginUpdate;
    try
      tvOperarios.DataController.RecordCount := 0;
      tvOperarios.DataController.RecordCount := Visibles.Count;
      for RowIdx := 0 to Visibles.Count - 1 do
      begin
        Op := Visibles[RowIdx];
        FOperarioRowIds[RowIdx] := Op.Id;
        TotalAbs := Length(FAbsRepo.GetByOperario(Op.Id));
        tvOperarios.DataController.Values[RowIdx, colOpNombre.Index] :=
          Op.Nombre;
        tvOperarios.DataController.Values[RowIdx, colOpTotal.Index] :=
          TotalAbs;
        tvOperarios.DataController.Values[RowIdx, colOpFiltro.Index] :=
          CountAusenciasFiltro(Op.Id);
      end;
    finally
      tvOperarios.EndUpdate;
    end;
  finally
    Visibles.Free;
  end;

  // Restaurar seleccion previa si sigue visible
  if PrevId > 0 then
    SelectOperarioInList(PrevId);
end;

function TfrmOperarioAusencias.CountAusenciasFiltro(OpId: Integer): Integer;
var
  All: TArray<TAusencia>;
  I, AnoFiltro, TipoFiltro: Integer;
begin
  Result := 0;
  if not Assigned(FAbsRepo) then Exit;
  All := FAbsRepo.GetByOperario(OpId);

  AnoFiltro := 0;
  if cbFiltroAno.ItemIndex > 0 then
    AnoFiltro := StrToIntDef(cbFiltroAno.Items[cbFiltroAno.ItemIndex], 0);
  TipoFiltro := -1;
  if cbFiltroTipo.ItemIndex > 0 then
    TipoFiltro := cbFiltroTipo.ItemIndex - 1;

  for I := 0 to High(All) do
  begin
    if (AnoFiltro > 0) and (YearOf(All[I].FechaInicio) <> AnoFiltro) and
       (YearOf(All[I].FechaFin) <> AnoFiltro) then Continue;
    if (TipoFiltro >= 0) and (Ord(All[I].Tipo) <> TipoFiltro) then Continue;
    Inc(Result);
  end;
end;

procedure TfrmOperarioAusencias.SelectOperarioInList(OpId: Integer);
var
  I: Integer;
begin
  for I := 0 to High(FOperarioRowIds) do
    if FOperarioRowIds[I] = OpId then
    begin
      tvOperarios.DataController.FocusedRecordIndex := I;
      FCurrentOpId := OpId;
      RefreshAusencias;
      Exit;
    end;
end;

function TfrmOperarioAusencias.CurrentOperarioNombre: string;
var
  Op: TOperario;
begin
  if (FCurrentOpId > 0) and FOpRepo.GetOperarioById(FCurrentOpId, Op) then
    Result := Op.Nombre
  else
    Result := '';
end;

procedure TfrmOperarioAusencias.edBuscarChange(Sender: TObject);
begin
  ApplyFilterOperarios;
end;

procedure TfrmOperarioAusencias.cbFiltroDeptoChange(Sender: TObject);
begin
  ApplyFilterOperarios;
end;

procedure TfrmOperarioAusencias.tvOperariosFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
var
  Idx, OpId: Integer;
begin
  if AFocusedRecord = nil then Exit;
  Idx := AFocusedRecord.RecordIndex;
  if (Idx < 0) or (Idx > High(FOperarioRowIds)) then Exit;
  OpId := FOperarioRowIds[Idx];
  if OpId <> FCurrentOpId then
  begin
    FCurrentOpId := OpId;
    RefreshAusencias;
  end;
end;

procedure TfrmOperarioAusencias.RefreshAusencias;
var
  All, Filt: TArray<TAusencia>;
  I, J, AnoFiltro, TipoFiltro: Integer;
  L: TList<TAusencia>;
  Tmp: TAusencia;
begin
  if (FCurrentOpId <= 0) or not Assigned(FAbsRepo) then
  begin
    SetLength(FCurrentRows, 0);
    RefreshGrid;
    RefreshCalendario;
    Exit;
  end;
  All := FAbsRepo.GetByOperario(FCurrentOpId);

  AnoFiltro := 0;
  if (cbFiltroAno.ItemIndex > 0) then
    AnoFiltro := StrToIntDef(cbFiltroAno.Items[cbFiltroAno.ItemIndex], 0);
  TipoFiltro := -1;
  if cbFiltroTipo.ItemIndex > 0 then
    TipoFiltro := cbFiltroTipo.ItemIndex - 1;

  L := TList<TAusencia>.Create;
  try
    for I := 0 to High(All) do
    begin
      if (AnoFiltro > 0) and (YearOf(All[I].FechaInicio) <> AnoFiltro) and
         (YearOf(All[I].FechaFin) <> AnoFiltro) then Continue;
      if (TipoFiltro >= 0) and (Ord(All[I].Tipo) <> TipoFiltro) then Continue;
      L.Add(All[I]);
    end;
    Filt := L.ToArray;
  finally
    L.Free;
  end;

  // Ordenar por fecha de inicio (insertion sort, listas peque'nas)
  for I := 1 to High(Filt) do
  begin
    Tmp := Filt[I];
    J := I - 1;
    while (J >= 0) and (Filt[J].FechaInicio > Tmp.FechaInicio) do
    begin
      Filt[J + 1] := Filt[J];
      Dec(J);
    end;
    Filt[J + 1] := Tmp;
  end;

  FCurrentRows := Filt;
  RefreshGrid;
  RefreshCalendario;
  // Actualizar contador en columna del operario actual
  for I := 0 to High(FOperarioRowIds) do
    if FOperarioRowIds[I] = FCurrentOpId then
    begin
      tvOperarios.DataController.Values[I, colOpTotal.Index] :=
        Length(FAbsRepo.GetByOperario(FCurrentOpId));
      tvOperarios.DataController.Values[I, colOpFiltro.Index] :=
        CountAusenciasFiltro(FCurrentOpId);
      Break;
    end;
end;

procedure TfrmOperarioAusencias.RefreshGrid;
var
  I: Integer;
  Dias: Integer;
  A: TAusencia;
begin
  tvAusencias.BeginUpdate;
  try
    tvAusencias.DataController.RecordCount := 0;
    tvAusencias.DataController.RecordCount := Length(FCurrentRows);
    for I := 0 to High(FCurrentRows) do
    begin
      A := FCurrentRows[I];
      tvAusencias.DataController.Values[I, colTipo.Index] :=
        TipoAusenciaToStr(A.Tipo);
      if A.EsHoraria then
      begin
        tvAusencias.DataController.Values[I, colInicio.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', A.FechaInicio);
        tvAusencias.DataController.Values[I, colFin.Index] :=
          FormatDateTime('hh:nn', A.FechaFin);
        tvAusencias.DataController.Values[I, colDias.Index] :=
          Format('%.1f h', [(A.FechaFin - A.FechaInicio) * 24]);
      end
      else
      begin
        tvAusencias.DataController.Values[I, colInicio.Index] :=
          FormatDateTime('dd/mm/yyyy', A.FechaInicio);
        tvAusencias.DataController.Values[I, colFin.Index] :=
          FormatDateTime('dd/mm/yyyy', A.FechaFin);
        Dias := Max(1, Trunc(A.FechaFin - A.FechaInicio));
        tvAusencias.DataController.Values[I, colDias.Index] :=
          Format('%d d', [Dias]);
      end;
      tvAusencias.DataController.Values[I, colDescripcion.Index] :=
        A.Descripcion;
    end;
  finally
    tvAusencias.EndUpdate;
  end;
end;

procedure TfrmOperarioAusencias.RefreshCalendario;
begin
  if Assigned(FCalendario) then
    FCalendario.SetAusencias(FCurrentRows);
end;

procedure TfrmOperarioAusencias.UpdateMesAnoLabel;
const
  Meses: array[1..12] of string = (
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre');
begin
  if Assigned(FCalendario) then
    lblMesAno.Caption := Format('%s %d',
      [Meses[FCalendario.Month], FCalendario.Year]);
end;

procedure TfrmOperarioAusencias.cbFiltroAnoChange(Sender: TObject);
begin
  ApplyFilterOperarios;  // recalcula columna Filtro
  RefreshAusencias;
end;

procedure TfrmOperarioAusencias.cbFiltroTipoChange(Sender: TObject);
begin
  ApplyFilterOperarios;
  RefreshAusencias;
end;

function TfrmOperarioAusencias.HasOverlap(const A: TAusencia;
  out OtherDesc: string): Boolean;
var
  All: TArray<TAusencia>;
  I: Integer;
begin
  Result := False;
  OtherDesc := '';
  if not Assigned(FAbsRepo) then Exit;
  All := FAbsRepo.GetByOperario(A.OperarioId);
  for I := 0 to High(All) do
  begin
    if All[I].Id = A.Id then Continue;  // el mismo
    if (A.FechaInicio < All[I].FechaFin) and
       (A.FechaFin > All[I].FechaInicio) then
    begin
      OtherDesc := Format('%s  %s - %s',
        [TipoAusenciaToStr(All[I].Tipo),
         FormatDateTime('dd/mm/yyyy', All[I].FechaInicio),
         FormatDateTime('dd/mm/yyyy', All[I].FechaFin)]);
      Exit(True);
    end;
  end;
end;

function TfrmOperarioAusencias.ConfirmOverlap(const OtherDesc: string): Boolean;
begin
  Result := MessageDlg(
    'La ausencia se solapa con otra existente:'#13#10 + OtherDesc + #13#10 +
    #13#10'?Forzar guardado igualmente?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmOperarioAusencias.DoEditAusencia(var A: TAusencia; IsNew: Boolean);
var
  OtherDesc: string;
begin
  if not TfrmAusenciaEdit.Execute(A, CurrentOperarioNombre) then Exit;

  if HasOverlap(A, OtherDesc) and not ConfirmOverlap(OtherDesc) then Exit;

  if IsNew then
    FAbsRepo.Add(A)
  else
    FAbsRepo.Update(A);
  RefreshAusencias;
end;

procedure TfrmOperarioAusencias.btnNuevaClick(Sender: TObject);
var
  A: TAusencia;
begin
  if FCurrentOpId <= 0 then
  begin
    MessageDlg('Seleccione primero un operario.', mtInformation, [mbOK], 0);
    Exit;
  end;
  A := Default(TAusencia);
  A.OperarioId := FCurrentOpId;
  A.FechaInicio := Trunc(Now);
  A.FechaFin := Trunc(Now) + 1;
  A.Tipo := taVacaciones;
  DoEditAusencia(A, True);
end;

procedure TfrmOperarioAusencias.btnEditarClick(Sender: TObject);
var
  Idx: Integer;
  A: TAusencia;
begin
  Idx := tvAusencias.DataController.FocusedRecordIndex;
  if (Idx < 0) or (Idx > High(FCurrentRows)) then Exit;
  A := FCurrentRows[Idx];
  DoEditAusencia(A, False);
end;

procedure TfrmOperarioAusencias.btnEliminarClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := tvAusencias.DataController.FocusedRecordIndex;
  if (Idx < 0) or (Idx > High(FCurrentRows)) then Exit;
  if MessageDlg('?Eliminar la ausencia seleccionada?', mtConfirmation,
       [mbYes, mbNo], 0) <> mrYes then Exit;
  FAbsRepo.Remove(FCurrentRows[Idx].Id);
  RefreshAusencias;
end;

procedure TfrmOperarioAusencias.btnDuplicarClick(Sender: TObject);
var
  Idx, Dias: Integer;
  A: TAusencia;
  OtherDesc: string;
begin
  Idx := tvAusencias.DataController.FocusedRecordIndex;
  if (Idx < 0) or (Idx > High(FCurrentRows)) then Exit;
  A := FCurrentRows[Idx];
  A.Id := 0;
  Dias := Max(1, Trunc(A.FechaFin - A.FechaInicio));
  A.FechaInicio := IncYear(A.FechaInicio, 1);
  A.FechaFin := A.FechaInicio + Dias;
  if not TfrmAusenciaEdit.Execute(A, CurrentOperarioNombre) then Exit;
  if HasOverlap(A, OtherDesc) and not ConfirmOverlap(OtherDesc) then Exit;
  FAbsRepo.Add(A);
  RefreshAusencias;
end;

procedure TfrmOperarioAusencias.tvAusenciasDblClick(Sender: TObject);
begin
  btnEditarClick(nil);
end;

procedure TfrmOperarioAusencias.tvAusenciasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  R: TRect;
  S: string;
  TipoColor: TColor;
begin
  if AViewInfo.Item <> colTipo then Exit;
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if (RecIdx < 0) or (RecIdx > High(FCurrentRows)) then Exit;

  TipoColor := TipoAusenciaColor(FCurrentRows[RecIdx].Tipo);
  S := TipoAusenciaToStr(FCurrentRows[RecIdx].Tipo);

  R := AViewInfo.Bounds;
  ACanvas.Canvas.Brush.Color := clWhite;
  ACanvas.Canvas.FillRect(R);

  // Badge de color
  ACanvas.Canvas.Brush.Color := TipoColor;
  ACanvas.Canvas.Pen.Color := $00808080;
  ACanvas.Canvas.RoundRect(R.Left + 4, R.Top + 4, R.Left + 14, R.Bottom - 4,
    3, 3);

  // Texto
  ACanvas.Canvas.Brush.Style := bsClear;
  ACanvas.Canvas.Font.Color := $00303030;
  ACanvas.Canvas.TextOut(R.Left + 22, R.Top + 4, S);
  ACanvas.Canvas.Brush.Style := bsSolid;
  ADone := True;
end;

procedure TfrmOperarioAusencias.btnPrevMesClick(Sender: TObject);
begin
  FCalendario.StepMonth(-1);
  UpdateMesAnoLabel;
end;

procedure TfrmOperarioAusencias.btnNextMesClick(Sender: TObject);
begin
  FCalendario.StepMonth(1);
  UpdateMesAnoLabel;
end;

procedure TfrmOperarioAusencias.btnHoyCalClick(Sender: TObject);
var
  Y, M, D: Word;
begin
  DecodeDate(Now, Y, M, D);
  FCalendario.SetMonth(Y, M);
  UpdateMesAnoLabel;
end;

procedure TfrmOperarioAusencias.CalendarioOnDayClick(Sender: TObject);
var
  D: TDateTime;
  I: Integer;
  A: TAusencia;
begin
  D := FCalendario.ClickedDate;
  if D <= 0 then Exit;
  // Si hay ausencia ese dia, foco al grid + edit
  for I := 0 to High(FCurrentRows) do
    if (D >= Trunc(FCurrentRows[I].FechaInicio)) and
       (D < Trunc(FCurrentRows[I].FechaFin)) then
    begin
      tvAusencias.DataController.FocusedRecordIndex := I;
      pcMain.ActivePage := tsLista;
      Exit;
    end;
  // Si no hay, oferta crear con ese dia preseleccionado
  if FCurrentOpId <= 0 then Exit;
  if MessageDlg(Format('No hay ausencia el %s. ?Crear una nueva?',
       [FormatDateTime('dd/mm/yyyy', D)]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  A := Default(TAusencia);
  A.OperarioId := FCurrentOpId;
  A.FechaInicio := D;
  A.FechaFin := D + 1;
  A.Tipo := taVacaciones;
  DoEditAusencia(A, True);
end;

procedure TfrmOperarioAusencias.btnExportarCsvClick(Sender: TObject);
var
  SL: TStringList;
  I, Dias: Integer;
begin
  if Length(FCurrentRows) = 0 then
  begin
    MessageDlg('No hay ausencias que exportar.', mtInformation, [mbOK], 0);
    Exit;
  end;
  SaveDialog1.FileName := Format('Ausencias_%s_%s.csv',
    [CurrentOperarioNombre, FormatDateTime('yyyymmdd', Now)]);
  if not SaveDialog1.Execute then Exit;

  SL := TStringList.Create;
  try
    SL.Add('Tipo;FechaInicio;FechaFin;Dias;Descripcion');
    for I := 0 to High(FCurrentRows) do
    begin
      Dias := Max(1, Trunc(FCurrentRows[I].FechaFin -
        FCurrentRows[I].FechaInicio));
      SL.Add(Format('%s;%s;%s;%d;%s',
        [TipoAusenciaToStr(FCurrentRows[I].Tipo),
         FormatDateTime('yyyy-mm-dd', FCurrentRows[I].FechaInicio),
         FormatDateTime('yyyy-mm-dd', FCurrentRows[I].FechaFin),
         Dias,
         StringReplace(FCurrentRows[I].Descripcion, ';', ',',
           [rfReplaceAll])]));
    end;
    SL.SaveToFile(SaveDialog1.FileName, TEncoding.UTF8);
  finally
    SL.Free;
  end;
end;

procedure TfrmOperarioAusencias.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
