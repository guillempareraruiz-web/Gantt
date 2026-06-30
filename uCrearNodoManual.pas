unit uCrearNodoManual;

// =============================================================================
// Dialogo "Crear nodo manual" (V066).
//
// Permite al usuario crear un nodo en el plan que NO proviene del ERP: tareas
// de diseno, administrativas, oficina tecnica... El usuario indica la operacion
// (obligatoria, del catalogo), el centro (obligatorio), la duracion en minutos
// (minimo 5) y la fecha/hora de inicio. La descripcion es opcional (si se deja
// vacia, el nombre del nodo sera la operacion). Opcionalmente puede vincular el
// nodo a una OF / Pedido / Proyecto, pero sigue siendo MANUAL (Source='MAN').
//
// El nodo creado convive con los nodos ERP en el mismo plan: el scheduler, los
// lotes, las alertas y los snapshots lo tratan igual. Por defecto nace LIBRE
// (LibreMovimiento=True), por lo que el recalculo automatico puede moverlo como
// a cualquier nodo ERP.
//
// El dialogo SOLO recoge datos y los devuelve via Execute; la persistencia la
// hace el llamador (uVistaGantt) para reusar su transaccion y refresco de plan.
// =============================================================================

interface

uses
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  Winapi.Windows,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Mask, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.Graphics,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit,
  uGanttTypes;

const
  DURACION_MANUAL_MIN_DEFAULT = 30;   // minutos sugeridos al abrir el dialogo
  DURACION_MANUAL_MIN_PERMITIDA = 5;  // minimo permitido (minutos)

type
  // Resultado del dialogo: datos del nodo manual a crear.
  TNodoManualData = record
    Caption: string;          // descripcion (FS_PL_Node.Caption); si vacia = Operacion
    Operacion: string;        // operacion del catalogo (obligatoria)
    CenterId: Integer;        // centro de planificacion (obligatorio)
    DuracionMin: Double;      // duracion en minutos (minimo 5)
    FechaInicio: TDateTime;   // inicio; el fin se calcula = inicio + duracion
    FechaCompromiso: TDateTime; // fecha compromiso/entrega (0 = sin fecha)
    // Vinculo opcional a ERP. TipoOrigen vacio = sin vinculo.
    RawItemTipoOrigen: string; // '', 'OF ', 'PED', 'PRJ'
    RawItemClaveERP: string;   // clave libre del documento ERP (opcional)
  end;

  TfrmCrearNodoManual = class(TForm)
    pnlHeader: TPanel;
    lblHeaderTitle: TLabel;
    lblHeaderSub: TLabel;
    shpHeaderLine: TShape;
    pnlBody: TPanel;
    lblOperacion: TLabel;
    cbOperacion: TComboBox;
    lblCentro: TLabel;
    cbCentro: TComboBox;
    lblDescripcion: TLabel;
    edtDescripcion: TEdit;
    lblDuracion: TLabel;
    seDuracion: TcxSpinEdit;
    lblDuracionUnit: TLabel;
    lblInicio: TLabel;
    dtpFecha: TDateTimePicker;
    dtpHora: TDateTimePicker;
    chkUsaCompromiso: TCheckBox;
    dtpCompromiso: TDateTimePicker;
    lblVinculo: TLabel;
    cbVinculo: TComboBox;
    lblClaveERP: TLabel;
    edtClaveERP: TEdit;
    pnlButtons: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    procedure cbVinculoChange(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure chkUsaCompromisoClick(Sender: TObject);
  private
    FCentros: TArray<TCentreTreball>;
    procedure CargarCentros;
    procedure CargarOperaciones;
  public
    // Abre el dialogo. AFechaInicioDefecto es la fecha sugerida (p.ej. el centro
    // de la vista del Gantt). APreselectCenterId es el centro a preseleccionar
    // (el que esta bajo el cursor del right-click); -1 = ninguno -> primer centro.
    // Devuelve True si el usuario acepto, rellenando AData con los valores.
    class function Execute(const ACentros: TArray<TCentreTreball>;
      AFechaInicioDefecto: TDateTime; APreselectCenterId: Integer;
      out AData: TNodoManualData): Boolean;
  end;

implementation

uses
  Data.Win.ADODB, uDMPlanner;

{$R *.dfm}

class function TfrmCrearNodoManual.Execute(
  const ACentros: TArray<TCentreTreball>;
  AFechaInicioDefecto: TDateTime; APreselectCenterId: Integer;
  out AData: TNodoManualData): Boolean;
var
  F: TfrmCrearNodoManual;
  iSel, i: Integer;
begin
  Result := False;
  F := TfrmCrearNodoManual.Create(nil);
  try
    F.FCentros := ACentros;
    F.CargarCentros;
    F.CargarOperaciones;

    // Preseleccionar el centro bajo el cursor del right-click, si se indico.
    if APreselectCenterId >= 0 then
      for i := 0 to High(F.FCentros) do
        if F.FCentros[i].Id = APreselectCenterId then
        begin
          F.cbCentro.ItemIndex := i;
          Break;
        end;

    if AFechaInicioDefecto < 1 then
      AFechaInicioDefecto := Now;
    F.dtpFecha.Date := DateOf(AFechaInicioDefecto);
    F.dtpHora.Time := TimeOf(AFechaInicioDefecto);

    // Fecha compromiso desactivada por defecto; sugerimos el dia del inicio.
    F.chkUsaCompromiso.Checked := False;
    F.dtpCompromiso.Date := DateOf(AFechaInicioDefecto);
    F.chkUsaCompromisoClick(nil);

    if F.ShowModal <> mrOk then Exit;

    AData := Default(TNodoManualData);

    AData.Operacion := Trim(F.cbOperacion.Text);

    // Descripcion opcional: si esta vacia, el nombre del nodo es la operacion.
    AData.Caption := Trim(F.edtDescripcion.Text);
    if AData.Caption = '' then
      AData.Caption := AData.Operacion;

    iSel := F.cbCentro.ItemIndex;
    if (iSel >= 0) and (iSel < Length(F.FCentros)) then
      AData.CenterId := F.FCentros[iSel].Id
    else
      AData.CenterId := -1; // Sin Centro

    AData.DuracionMin := F.seDuracion.Value;  // TcxSpinEdit.Value (Variant numerico)

    AData.FechaInicio := DateOf(F.dtpFecha.Date) + TimeOf(F.dtpHora.Time);

    // Fecha compromiso/entrega: 0 si el usuario no la activo.
    if F.chkUsaCompromiso.Checked then
      AData.FechaCompromiso := DateOf(F.dtpCompromiso.Date)
    else
      AData.FechaCompromiso := 0;

    // Vinculo: ItemIndex 0 = Ninguno; 1 = OF; 2 = Pedido; 3 = Proyecto.
    case F.cbVinculo.ItemIndex of
      1: AData.RawItemTipoOrigen := 'OF ';
      2: AData.RawItemTipoOrigen := 'PED';
      3: AData.RawItemTipoOrigen := 'PRJ';
    else
      AData.RawItemTipoOrigen := '';
    end;
    if AData.RawItemTipoOrigen <> '' then
      AData.RawItemClaveERP := Trim(F.edtClaveERP.Text)
    else
      AData.RawItemClaveERP := '';

    Result := True;
  finally
    F.Free;
  end;
end;

procedure TfrmCrearNodoManual.CargarCentros;
var
  C: TCentreTreball;
  S: string;
begin
  cbCentro.Items.BeginUpdate;
  try
    cbCentro.Items.Clear;
    for C in FCentros do
    begin
      S := C.Titulo;
      if C.Subtitulo <> '' then
        S := S + ' - ' + C.Subtitulo;
      cbCentro.Items.Add(S);
    end;
  finally
    cbCentro.Items.EndUpdate;
  end;
  // No preseleccionamos: el centro es obligatorio y debe elegirlo el usuario
  // (salvo que el right-click lo preseleccione en Execute).
  cbCentro.ItemIndex := -1;
end;

procedure TfrmCrearNodoManual.CargarOperaciones;
var
  Q: TADOQuery;
begin
  cbOperacion.Items.BeginUpdate;
  try
    cbOperacion.Items.Clear;
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT Operacion FROM FS_PL_OperationType ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) + ' ' +
        'ORDER BY Operacion';
      Q.Open;
      while not Q.Eof do
      begin
        if Trim(Q.FieldByName('Operacion').AsString) <> '' then
          cbOperacion.Items.Add(Trim(Q.FieldByName('Operacion').AsString));
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    cbOperacion.Items.EndUpdate;
  end;
  cbOperacion.ItemIndex := -1;
end;

procedure TfrmCrearNodoManual.cbVinculoChange(Sender: TObject);
var
  TieneVinculo: Boolean;
begin
  // El campo de clave ERP solo tiene sentido si hay vinculo seleccionado.
  TieneVinculo := cbVinculo.ItemIndex > 0;
  lblClaveERP.Enabled := TieneVinculo;
  edtClaveERP.Enabled := TieneVinculo;
  if not TieneVinculo then
    edtClaveERP.Text := '';
end;

procedure TfrmCrearNodoManual.chkUsaCompromisoClick(Sender: TObject);
begin
  // El selector de fecha compromiso solo se habilita si la casilla esta marcada.
  dtpCompromiso.Enabled := chkUsaCompromiso.Checked;
end;

procedure TfrmCrearNodoManual.btnAceptarClick(Sender: TObject);
begin
  // Operacion: obligatoria.
  if Trim(cbOperacion.Text) = '' then
  begin
    MessageDlg('Selecciona una operaci'#243'n.', mtWarning, [mbOK], 0);
    cbOperacion.SetFocus;
    Exit;
  end;

  // Centro: obligatorio.
  if cbCentro.ItemIndex < 0 then
  begin
    MessageDlg('Selecciona un centro.', mtWarning, [mbOK], 0);
    cbCentro.SetFocus;
    Exit;
  end;

  // Duracion: minimo permitido.
  if seDuracion.Value < DURACION_MANUAL_MIN_PERMITIDA then
  begin
    MessageDlg(Format('La duraci'#243'n m'#237'nima es de %d minutos.',
      [DURACION_MANUAL_MIN_PERMITIDA]), mtWarning, [mbOK], 0);
    seDuracion.SetFocus;
    Exit;
  end;

  ModalResult := mrOk;
end;

end.
