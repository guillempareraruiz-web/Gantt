unit uMoverFecha;
// Dialogo modal para "Mover" una OF/OT/OP a una fecha destino (planificacion
// forward = empieza en fecha, o backward = acaba en fecha; el sentido lo decide
// el llamador, este form solo recoge la FECHA).
//
// El usuario puede teclear la fecha a mano o elegirla de varios origenes:
//   - Fecha entrega           (disponible: viene del nodo)
//   - Fecha recuperacion stock (TODO: pendiente de calculo MRP)
//   - Fecha final de la cola   (TODO: pendiente de calculo)
// De momento solo "Entrega" rellena el selector; las otras dos quedan
// deshabilitadas hasta definir su origen.
interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar,
  dxSkinsCore, dxSkinsDefaultPainters;

type
  TfrmMoverFecha = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    lblOrigen: TLabel;
    rbEntrega: TRadioButton;
    rbRecuperacion: TRadioButton;
    rbFinalCola: TRadioButton;
    rbManual: TRadioButton;
    lblFecha: TLabel;
    dtFecha: TcxDateEdit;
    lblHelp: TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure rbEntregaClick(Sender: TObject);
    procedure rbManualClick(Sender: TObject);
  private
    FFechaEntrega: TDateTime;   // 0 si el nodo no tiene fecha de entrega
    function AFechaDefectoValido(const A: TDateTime): Boolean;
  public
    // ATitulo/ASubtitulo: textos del header (p.ej. 'Mover OF hacia atras').
    // AFechaEntrega: fecha de entrega del nodo (0 si no aplica -> radio disabled).
    // AFechaDefecto: valor inicial del selector (normalmente la entrega o hoy).
    // Devuelve True y AFechaDestino si el usuario acepta.
    class function Execute(const ATitulo, ASubtitulo: string;
      const AFechaEntrega, AFechaDefecto: TDateTime;
      out AFechaDestino: TDateTime): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmMoverFecha.Execute(const ATitulo, ASubtitulo: string;
  const AFechaEntrega, AFechaDefecto: TDateTime;
  out AFechaDestino: TDateTime): Boolean;
var
  F: TfrmMoverFecha;
begin
  AFechaDestino := 0;
  F := TfrmMoverFecha.Create(Application);
  try
    F.lblTitle.Caption := ATitulo;
    F.lblSubtitle.Caption := ASubtitulo;
    F.FFechaEntrega := AFechaEntrega;

    // La opcion "Entrega" solo esta disponible si el nodo tiene fecha de entrega.
    F.rbEntrega.Enabled := AFechaEntrega > 1;

    // Pendientes de implementar el origen de datos.
    F.rbRecuperacion.Enabled := False;
    F.rbFinalCola.Enabled := False;

    if F.AFechaDefectoValido(AFechaDefecto) then
      F.dtFecha.Date := AFechaDefecto
    else
      F.dtFecha.Date := Date;

    // Por defecto, si hay entrega, arrancamos en esa opcion; si no, manual.
    if F.rbEntrega.Enabled then
    begin
      F.rbEntrega.Checked := True;
      F.dtFecha.Date := AFechaEntrega;
    end
    else
      F.rbManual.Checked := True;

    Result := F.ShowModal = mrOk;
    if Result then
      AFechaDestino := F.dtFecha.Date;
  finally
    F.Free;
  end;
end;

function TfrmMoverFecha.AFechaDefectoValido(const A: TDateTime): Boolean;
begin
  Result := A > 1;
end;

procedure TfrmMoverFecha.rbEntregaClick(Sender: TObject);
begin
  // Al elegir "Entrega", el selector toma esa fecha (pero el usuario puede
  // retocarla luego; si lo hace, pasamos a modo manual desde el OnChange? no:
  // mantenemos simple, solo precarga el valor).
  if rbEntrega.Checked and (FFechaEntrega > 1) then
    dtFecha.Date := FFechaEntrega;
end;

procedure TfrmMoverFecha.rbManualClick(Sender: TObject);
begin
  // Modo manual: no toca el valor, el usuario escribe la fecha que quiera.
end;

procedure TfrmMoverFecha.btnOKClick(Sender: TObject);
begin
  if VarIsNull(dtFecha.EditValue) or (dtFecha.Date <= 1) then
  begin
    ShowMessage('Indica una fecha destino v'#225'lida.');
    ModalResult := mrNone;
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
