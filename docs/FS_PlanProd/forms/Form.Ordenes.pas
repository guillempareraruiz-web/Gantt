unit Form.Ordenes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids;

type
  TfrmOrdenes = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    pnlClient: TPanel;
    sgOrdenes: TStringGrid;
    pnlDetalle: TPanel;
    gbInfo: TGroupBox;
    lblCod: TLabel;
    lblDesc: TLabel;
    lblCentro: TLabel;
    lblPrioridad: TLabel;
    lblEstado: TLabel;
    lblCompromiso: TLabel;
    edtCod: TEdit;
    edtDesc: TEdit;
    edtCentro: TEdit;
    edtPrioridad: TEdit;
    edtEstado: TEdit;
    edtCompromiso: TEdit;
    gbOperaciones: TGroupBox;
    sgOperaciones: TStringGrid;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure sgOrdenesClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    procedure RefrescarGridOrdenes;
    procedure CargarDetalle(AIdx: Integer);
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils,
  System.Math,
  FS.PlanProd.Types,
  FS.PlanProd.SessionData;

function EstadoOrdenToStr(AE: TEstadoOrden): string;
begin
  case AE of
    eoPlanificada: Result := 'PLANIFICADA';
    eoLanzada: Result := 'LANZADA';
    eoEnCurso: Result := 'EN_CURSO';
    eoPausada: Result := 'PAUSADA';
    eoFinalizada: Result := 'FINALIZADA';
    eoCancelada: Result := 'CANCELADA';
  else
    Result := '?';
  end;
end;

procedure TfrmOrdenes.FormCreate(Sender: TObject);
begin
  // Cabecera tabla órdenes
  sgOrdenes.ColCount := 6;
  sgOrdenes.RowCount := 1;
  sgOrdenes.Cells[0, 0] := 'Código';
  sgOrdenes.Cells[1, 0] := 'Descripción';
  sgOrdenes.Cells[2, 0] := 'Centro';
  sgOrdenes.Cells[3, 0] := 'Pri';
  sgOrdenes.Cells[4, 0] := 'Estado';
  sgOrdenes.Cells[5, 0] := 'Compromiso';
  sgOrdenes.ColWidths[0] := 110;
  sgOrdenes.ColWidths[1] := 200;
  sgOrdenes.ColWidths[2] := 80;
  sgOrdenes.ColWidths[3] := 30;
  sgOrdenes.ColWidths[4] := 90;
  sgOrdenes.ColWidths[5] := 130;

  // Cabecera tabla operaciones (con NumOpMin/Max)
  sgOperaciones.ColCount := 7;
  sgOperaciones.RowCount := 1;
  sgOperaciones.Cells[0, 0] := 'Sec';
  sgOperaciones.Cells[1, 0] := 'Operación';
  sgOperaciones.Cells[2, 0] := 'Min';
  sgOperaciones.Cells[3, 0] := 'OpMin';
  sgOperaciones.Cells[4, 0] := 'OpMax';
  sgOperaciones.Cells[5, 0] := 'Estado';
  sgOperaciones.Cells[6, 0] := 'Asignados';
  sgOperaciones.ColWidths[0] := 40;
  sgOperaciones.ColWidths[1] := 130;
  sgOperaciones.ColWidths[2] := 50;
  sgOperaciones.ColWidths[3] := 50;
  sgOperaciones.ColWidths[4] := 50;
  sgOperaciones.ColWidths[5] := 90;
  sgOperaciones.ColWidths[6] := 120;

  RefrescarGridOrdenes;
  if Session.Ordenes.Count > 0 then
  begin
    sgOrdenes.Row := 1;
    CargarDetalle(0);
  end;
end;

procedure TfrmOrdenes.RefrescarGridOrdenes;
var
  I: Integer;
  LO: TOrdenTrabajo;
begin
  sgOrdenes.RowCount := Max(2, Session.Ordenes.Count + 1);
  for I := 0 to Session.Ordenes.Count - 1 do
  begin
    LO := Session.Ordenes[I];
    sgOrdenes.Cells[0, I + 1] := LO.CodOrden;
    sgOrdenes.Cells[1, I + 1] := LO.Descripcion;
    sgOrdenes.Cells[2, I + 1] := LO.CodCentroRequerido;
    sgOrdenes.Cells[3, I + 1] := IntToStr(LO.Prioridad);
    sgOrdenes.Cells[4, I + 1] := EstadoOrdenToStr(LO.Estado);
    sgOrdenes.Cells[5, I + 1] := FormatDateTime('dd/mm hh:nn',
      LO.FechaCompromiso);
  end;
  if Session.Ordenes.Count = 0 then
  begin
    sgOrdenes.Cells[0, 1] := '';
    sgOrdenes.Cells[1, 1] := '';
  end;
end;

procedure TfrmOrdenes.sgOrdenesClick(Sender: TObject);
var
  LRow: Integer;
begin
  LRow := sgOrdenes.Row;
  if (LRow >= 1) and (LRow - 1 < Session.Ordenes.Count) then
    CargarDetalle(LRow - 1);
end;

procedure TfrmOrdenes.CargarDetalle(AIdx: Integer);
var
  LO: TOrdenTrabajo;
  LOp: TOperacionOrden;
  I, J: Integer;
  LEstadoOp, LAsignados: string;
begin
  LO := Session.Ordenes[AIdx];

  edtCod.Text := LO.CodOrden;
  edtDesc.Text := LO.Descripcion;
  edtCentro.Text := LO.CodCentroRequerido;
  edtPrioridad.Text := IntToStr(LO.Prioridad);
  edtEstado.Text := EstadoOrdenToStr(LO.Estado);
  edtCompromiso.Text := FormatDateTime('dd/mm/yyyy hh:nn', LO.FechaCompromiso);

  sgOperaciones.RowCount := Max(2, LO.Operaciones.Count + 1);
  for I := 0 to LO.Operaciones.Count - 1 do
  begin
    LOp := LO.Operaciones[I];
    sgOperaciones.Cells[0, I + 1] := IntToStr(LOp.NumSecuencia);
    sgOperaciones.Cells[1, I + 1] := LOp.CodOperacion;
    sgOperaciones.Cells[2, I + 1] := IntToStr(LOp.DuracionMin);
    sgOperaciones.Cells[3, I + 1] := IntToStr(LOp.NumOperariosMin);
    sgOperaciones.Cells[4, I + 1] := IntToStr(LOp.NumOperariosMax);

    if LOp.Finalizada then
      LEstadoOp := 'FIN'
    else if LOp.Iniciada then
      LEstadoOp := 'EN_CURSO'
    else
      LEstadoOp := 'PENDIENTE';
    sgOperaciones.Cells[5, I + 1] := LEstadoOp;

    LAsignados := '';
    if LOp.OperariosAsignados <> nil then
      for J := 0 to LOp.OperariosAsignados.Count - 1 do
      begin
        if LAsignados <> '' then LAsignados := LAsignados + ', ';
        LAsignados := LAsignados + LOp.OperariosAsignados[J];
      end;
    sgOperaciones.Cells[6, I + 1] := LAsignados;
  end;
  if LO.Operaciones.Count = 0 then
  begin
    sgOperaciones.Cells[0, 1] := '';
    sgOperaciones.Cells[1, 1] := '';
  end;
end;

procedure TfrmOrdenes.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
