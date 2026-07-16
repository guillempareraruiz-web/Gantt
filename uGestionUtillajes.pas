unit uGestionUtillajes;
// Listado maestro de utillajes. El detalle se edita en uUtillajeFicha
// (un form por utillaje); aqui solo se listan, se filtran y se abren.
//
// Entidad 100% Planner: Sage200 no modela utillajes, asi que no hay
// sincronizacion ERP en esta pantalla.
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxSpinEdit, cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  cxGeometry, dxCoreGraphics, dxGDIPlusAPI, dxGDIPlusClasses,
  Data.Win.ADODB, Data.DB,
  uUtillajeTypes, uUtillajesRepo, dxSkinBasic, dxSkinBlack, dxSkinBlue,
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
  TfrmGestionUtillajes = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pbKpis: TPaintBox;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnEdit: TButton;
    btnDel: TButton;
    gridUtil: TcxGrid;
    tvUtil: TcxGridTableView;
    colId: TcxGridColumn;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    colTipo: TcxGridColumn;
    colUbicacion: TcxGridColumn;
    colEstado: TcxGridColumn;
    colSituacion: TcxGridColumn;
    colLibreDesde: TcxGridColumn;
    colOFs: TcxGridColumn;
    colCantidad: TcxGridColumn;
    colVida: TcxGridColumn;
    colDisponible: TcxGridColumn;
    colActivo: TcxGridColumn;
    lvUtil: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure tvUtilDblClick(Sender: TObject);
    procedure tvUtilGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure pbKpisPaint(Sender: TObject);
  private
    FRepo: TUtillajesRepo;
    FStyleVidaAgotada: TcxStyle;
    FStyleConflicto: TcxStyle;
    // KPIs del cabecero, recalculados en cada LoadGrid.
    FKpiTotal: Integer;
    FKpiEnUso: Integer;
    FKpiVida: Integer;       // vida agotada o al limite (>= 80%)
    FKpiConflicto: Integer;  // declarado no usable pero el plan lo usa
    FKpiSinPlan: Boolean;    // True = no hay plan activo -> KPIs de plan en '-'
    procedure LoadGrid;
    function SelectedId: Integer;
    procedure EditarSeleccionado;
    procedure PintarKPIs(G: TdxGPGraphics);
  public
    class procedure Execute;
  end;
implementation
{$R *.dfm}
uses
  System.Math,
  uDMPlanner, uHelpViewer, uUtillajeFicha;

// ARGB -> TdxAlphaColor ($AARRGGBB). Local: la de uKPICard no esta exportada.
function ARGB(A, R, G, B: Byte): TdxAlphaColor; inline;
begin
  Result := (Cardinal(A) shl 24) or (Cardinal(R) shl 16) or
            (Cardinal(G) shl 8) or Cardinal(B);
end;
class procedure TfrmGestionUtillajes.Execute;
var
  F: TfrmGestionUtillajes;
begin
  F := TfrmGestionUtillajes.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;
procedure TfrmGestionUtillajes.FormCreate(Sender: TObject);
begin
  FRepo := TUtillajesRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  // Rojo suave para las filas con la vida util agotada.
  FStyleVidaAgotada := TcxStyle.Create(Self);
  FStyleVidaAgotada.Color := $00D0D0FF;

  // Naranja para la discrepancia maestro/plan: el usuario dice que el utillaje
  // no se puede usar (mantenimiento, averiado...) pero el plan lo esta usando.
  FStyleConflicto := TcxStyle.Create(Self);
  FStyleConflicto.Color := $008CD3FF;
  tvUtil.OptionsData.Editing := False;   // el detalle se edita en la ficha
  tvUtil.OptionsSelection.CellSelect := False;

  // El OnPaint se asigna tambien aqui, no solo en el DFM: el IDE tiende a
  // borrar del DFM los handlers que no reconoce al abrir el form, y entonces
  // los KPIs dejan de pintarse sin ningun error visible.
  pbKpis.OnPaint := pbKpisPaint;

  LoadGrid;
  // Boton '?' en el caption + F1 = ayuda contextual. Requiere
  // BorderStyle = bsDialog para que Windows pinte el icono.
  THelpViewer.InstallHelp(Self, 'uGestionUtillajes', 'Gesti'#243'n de Utillajes');
end;
procedure TfrmGestionUtillajes.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
end;
procedure TfrmGestionUtillajes.LoadGrid;
var
  Rows: TArray<TUtillaje>;
  Sits: TArray<TUtillajeSituacion>;
  I, J, K: Integer;
  U: TUtillaje;
  Pct: Double;
  VidaTxt, SitTxt, OFsTxt: string;
  S: TUtillajeSituacion;
  Encontrada: Boolean;
begin
  Rows := FRepo.LoadAll;

  // Situacion CALCULADA del plan activo (no se guarda en BD: quedaria obsoleta
  // en cuanto se mueve un nodo). Si falla o no hay plan, el listado sigue
  // funcionando y las columnas de situacion quedan vacias.
  SetLength(Sits, 0);
  if DMPlanner.CurrentProjectId > 0 then
  try
    Sits := FRepo.LoadSituaciones(DMPlanner.CurrentProjectId, Now);
  except
    SetLength(Sits, 0);
  end;

  FKpiTotal := Length(Rows);
  FKpiEnUso := 0;
  FKpiVida := 0;
  FKpiConflicto := 0;
  FKpiSinPlan := Length(Sits) = 0;

  tvUtil.BeginUpdate;
  try
    tvUtil.DataController.RecordCount := 0;
    tvUtil.DataController.RecordCount := Length(Rows);
    for I := 0 to High(Rows) do
    begin
      U := Rows[I];

      if U.VidaUtilTotal <= 0 then
        VidaTxt := '-'
      else
      begin
        Pct := PorcentajeVidaConsumida(U);
        VidaTxt := Format('%.0f%% (%d/%d %s)',
          [Pct, U.ContadorActual, U.VidaUtilTotal,
           LowerCase(UnidadVidaToStr(U.UnidadVida))]);
        // "Al limite" = a partir del 80%: es el punto en el que conviene ir
        // preparando el recambio, no cuando ya se ha pasado.
        if Pct >= 80 then Inc(FKpiVida);
      end;

      // Cruzar con la situacion calculada.
      S := Default(TUtillajeSituacion);
      Encontrada := False;
      for J := 0 to High(Sits) do
        if Sits[J].UtillajeId = U.Id then
        begin
          S := Sits[J];
          Encontrada := True;
          Break;
        end;

      if not Encontrada then
      begin
        SitTxt := '';
        OFsTxt := '';
      end
      else
      begin
        case S.Situacion of
          suEnUso:
            begin
              SitTxt := Format('En uso (%d)', [S.NodosAhora]);
              Inc(FKpiEnUso);
              // Discrepancia maestro vs plan: el usuario declara que no se
              // puede usar, pero el plan lo esta usando ahora mismo.
              if EstadoBloqueaPlanificacion(U.Estado) then
                Inc(FKpiConflicto);
            end;
          suReservado:
            SitTxt := Format('Reservado (%d)', [S.NodosFuturos]);
        else
          SitTxt := 'Libre';
        end;
        OFsTxt := '';
        for K := 0 to High(S.OFsAfectadas) do
          if OFsTxt = '' then
            OFsTxt := S.OFsAfectadas[K]
          else
            OFsTxt := OFsTxt + ', ' + S.OFsAfectadas[K];
      end;

      tvUtil.DataController.Values[I, colId.Index]          := U.Id;
      tvUtil.DataController.Values[I, colCodigo.Index]      := U.Codigo;
      tvUtil.DataController.Values[I, colDescripcion.Index] := U.Descripcion;
      tvUtil.DataController.Values[I, colTipo.Index]        := U.Tipo;
      tvUtil.DataController.Values[I, colUbicacion.Index]   := U.Ubicacion;
      tvUtil.DataController.Values[I, colEstado.Index]      := EstadoUtillajeToStr(U.Estado);
      tvUtil.DataController.Values[I, colSituacion.Index]   := SitTxt;

      if Encontrada and (S.LibreDesde > 0) then
        tvUtil.DataController.Values[I, colLibreDesde.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', S.LibreDesde)
      else
        tvUtil.DataController.Values[I, colLibreDesde.Index] := '';

      tvUtil.DataController.Values[I, colOFs.Index]         := OFsTxt;
      tvUtil.DataController.Values[I, colCantidad.Index]    := U.Cantidad;
      tvUtil.DataController.Values[I, colVida.Index]        := VidaTxt;
      tvUtil.DataController.Values[I, colDisponible.Index]  := U.Disponible;
      tvUtil.DataController.Values[I, colActivo.Index]      := U.Activo;
    end;
  finally
    tvUtil.EndUpdate;
  end;

  // El recuento vive ahora en los KPIs del cabecero; el subtitulo explica de
  // que plan se estan calculando (o avisa de que no hay).
  if FKpiSinPlan then
    lblSubtitle.Caption := 'Cat'#225'logo de utillajes  '#183'  sin plan activo: no se ' +
      'puede calcular el uso'
  else
    lblSubtitle.Caption := 'Cat'#225'logo de utillajes  '#183'  uso calculado sobre el ' +
      'plan activo';

  pbKpis.Invalidate;   // repintar los KPIs con los valores nuevos
end;
procedure TfrmGestionUtillajes.tvUtilGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  V: Variant;
  S, Est: string;
begin
  if ARecord = nil then Exit;

  // 1. Discrepancia maestro vs plan (lo mas grave): el usuario declara que el
  //    utillaje no se puede usar, pero el plan lo esta usando ahora mismo.
  V := ARecord.Values[colSituacion.Index];
  if not (VarIsNull(V) or VarIsEmpty(V)) then
  begin
    S := VarToStr(V);
    V := ARecord.Values[colEstado.Index];
    if not (VarIsNull(V) or VarIsEmpty(V)) then
    begin
      Est := VarToStr(V);
      if (Pos('En uso', S) = 1) and
         EstadoBloqueaPlanificacion(StrToEstadoUtillaje(Est)) then
      begin
        AStyle := FStyleConflicto;
        Exit;
      end;
    end;
  end;

  // 2. Vida util agotada.
  V := ARecord.Values[colVida.Index];
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  S := VarToStr(V);
  // El texto de vida empieza por el porcentaje; marcar en rojo si >= 100%.
  if (S <> '-') and (Pos('%', S) > 0) then
  begin
    S := Copy(S, 1, Pos('%', S) - 1);
    if StrToIntDef(Trim(S), 0) >= 100 then
      AStyle := FStyleVidaAgotada;
  end;
end;
// Se pinta sobre un TPaintBox y no sobre el panel: TPanel.Canvas es protected
// (viene de TCustomControl) y no se puede tocar desde fuera. Mismo patron que
// pbKpis en uBacklogSchedPreview.
procedure TfrmGestionUtillajes.pbKpisPaint(Sender: TObject);
var
  G: TdxGPGraphics;
begin
  G := TdxGPGraphics.Create(pbKpis.Canvas.Handle);
  try
    G.SmoothingMode := smAntiAlias;
    G.TextRenderingHint := TextRenderingHintClearTypeGridFit;
    PintarKPIs(G);
  finally
    G.Free;
  end;
end;

procedure TfrmGestionUtillajes.PintarKPIs(G: TdxGPGraphics);
const
  KPI_W  = 132;      // ancho de cada bloque
  KPI_TOP = 6;
  MARGEN_DER = 20;
  N_KPI = 4;
var
  I, X: Integer;
  Valores, Rotulos: array[0..N_KPI - 1] of string;
  Colores: array[0..N_KPI - 1] of TdxAlphaColor;
  ColGris, ColBlanco, ColRotulo: TdxAlphaColor;

  // Mismo patron de dibujo de texto que uKPICard.
  procedure Texto(const S, AFontName: string; AEmSize: Single; ABold: Boolean;
    AColor: TdxAlphaColor; const R: TdxRectF);
  var
    F: TdxGPFont;
    B: TdxGPBrush;
    SF: TdxGPStringFormat;
    Sty: TdxGPFontStyle;
  begin
    if ABold then Sty := FontStyleBold else Sty := FontStyleRegular;
    F := TdxGPFont.Create(AFontName, AEmSize, Sty);
    B := TdxGPBrush.Create;
    SF := TdxGPStringFormat.Create;
    try
      B.Color := AColor;
      SF.Alignment := StringAlignmentFar;      // alineado a la derecha
      SF.LineAlignment := StringAlignmentCenter;
      G.DrawString(S, F, B, R, SF);
    finally
      SF.Free;
      B.Free;
      F.Free;
    end;
  end;

  // Blanco para lo normal; ambar/rojo solo cuando el numero pide accion.
  function Tono(ACount: Integer; AAmbar: Boolean): TdxAlphaColor;
  begin
    if ACount <= 0 then
      Result := ColGris
    else if AAmbar then
      Result := ARGB(255, $FF, $B0, $30)     // ambar
    else
      Result := ARGB(255, $FF, $6B, $6B);    // rojo suave (legible sobre oscuro)
  end;

begin
  ColBlanco := ARGB(255, 255, 255, 255);
  ColGris   := ARGB(160, 255, 255, 255);
  ColRotulo := ARGB(200, $9A, $B8, $E2);

  Valores[0] := IntToStr(FKpiTotal);
  Rotulos[0] := 'EN CAT'#193'LOGO';
  Colores[0] := ColBlanco;

  Rotulos[1] := 'EN USO AHORA';
  Rotulos[2] := 'VIDA AL L'#205'MITE';
  Rotulos[3] := 'EN CONFLICTO';

  if FKpiSinPlan then
  begin
    // Sin plan activo no se puede hablar de uso ni de conflictos: '-' es mas
    // honesto que un 0, que se leeria como "no hay ninguno".
    Valores[1] := '-';
    Colores[1] := ColGris;
    Valores[3] := '-';
    Colores[3] := ColGris;
  end
  else
  begin
    Valores[1] := IntToStr(FKpiEnUso);
    Colores[1] := ColBlanco;
    Valores[3] := IntToStr(FKpiConflicto);
    Colores[3] := Tono(FKpiConflicto, False);
  end;

  Valores[2] := IntToStr(FKpiVida);
  Colores[2] := Tono(FKpiVida, True);

  // Coordenadas relativas al PaintBox, que ya esta anclado a la derecha del
  // cabecero: los 4 bloques se reparten su ancho.
  X := pbKpis.Width - (KPI_W * N_KPI);
  if X < 0 then X := 0;

  for I := 0 to N_KPI - 1 do
  begin
    Texto(Valores[I], 'Segoe UI Semibold', 19, False, Colores[I],
      dxRectF(X, KPI_TOP, X + KPI_W, KPI_TOP + 30));
    Texto(Rotulos[I], 'Segoe UI', 7.5, False, ColRotulo,
      dxRectF(X, KPI_TOP + 30, X + KPI_W, KPI_TOP + 46));
    Inc(X, KPI_W);
  end;
end;

function TfrmGestionUtillajes.SelectedId: Integer;
var
  Rec: TcxCustomGridRecord;
  V: Variant;
begin
  // Se lee el ID del propio registro enfocado, NO de FIds por posicion: al
  // ordenar por una cabecera el indice de fila deja de coincidir con el
  // indice de registro y se acabaria editando/borrando otro utillaje.
  Result := 0;
  Rec := tvUtil.Controller.FocusedRecord;
  if Rec = nil then Exit;
  V := Rec.Values[colId.Index];
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  Result := V;
end;
procedure TfrmGestionUtillajes.EditarSeleccionado;
var
  Id: Integer;
begin
  Id := SelectedId;
  if Id <= 0 then Exit;
  if TfrmUtillajeFicha.Execute(Id) then
    LoadGrid;
end;
procedure TfrmGestionUtillajes.btnAddClick(Sender: TObject);
begin
  if TfrmUtillajeFicha.Execute(0) then
    LoadGrid;
end;
procedure TfrmGestionUtillajes.btnEditClick(Sender: TObject);
begin
  EditarSeleccionado;
end;
procedure TfrmGestionUtillajes.tvUtilDblClick(Sender: TObject);
begin
  EditarSeleccionado;
end;
procedure TfrmGestionUtillajes.btnDelClick(Sender: TObject);
var
  Id: Integer;
  Codigo: string;
  Rec: TcxCustomGridRecord;
begin
  Id := SelectedId;
  if Id <= 0 then Exit;
  Rec := tvUtil.Controller.FocusedRecord;
  if Rec = nil then Exit;
  Codigo := VarToStr(Rec.Values[colCodigo.Index]);
  if MessageDlg('Eliminar el utillaje ' + Codigo + '?' + sLineBreak + sLineBreak +
    'Se borraran tambi'#233'n sus relaciones con centros, art'#237'culos y operaciones.' +
    sLineBreak + 'Si solo quiere retirarlo, desmarque Activo en su ficha.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
    FRepo.Delete(Id);
  except
    on E: Exception do
    begin
      // Tipicamente una FK desde FS_PL_MoldUtillaje.
      ShowMessage('No se ha podido eliminar el utillaje.' + sLineBreak +
        'Puede que est'#233' asignado a alg'#250'n molde.' + sLineBreak + sLineBreak +
        E.Message);
      Exit;
    end;
  end;
  LoadGrid;
end;
end.
