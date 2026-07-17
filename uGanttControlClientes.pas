unit uGanttControlClientes;

{
  TGanttControlClientes - Control de Gantt con las FILAS = clientes.

  Vista de CARGA COMERCIAL: una fila por cliente, las barras son los trabajos
  (nodos) comprometidos con ese cliente. Sirve para ver de un vistazo cuanta
  carga hay por cliente y cuando.

  Se implementa como subclase de TGanttControlGrupo (que ya resuelve todo el
  layout por "grupos" a partir de una clave/caption): solo cambia
  ResolveNodeGroup para agrupar por CodigoCliente en lugar de por padre ERP.

  Es SOLO LECTURA (como Utillajes): una vista de consulta comercial no deberia
  reprogramar. Cortamos el arranque de drag anulando el nodo pulsado, igual
  patron que TGanttControlUtillajes.
}

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls,
  uGanttControl, uGanttControlGrupo, uGanttTypes;

type
  TGanttControlClientes = class(TGanttControlGrupo)
  protected
    // Agrupa por cliente (CodigoCliente del TNodeData) en vez de por padre ERP.
    function ResolveNodeGroup(const ANodeIndex: Integer;
      out AClave, ACaption: string): Boolean; override;
  public
    // Solo lectura: se puede navegar/seleccionar/hover pero no arrastrar nodos.
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  end;

implementation

function TGanttControlClientes.ResolveNodeGroup(const ANodeIndex: Integer;
  out AClave, ACaption: string): Boolean;
var
  D: TNodeData;
  Cli: string;
begin
  AClave := '';
  ACaption := '';
  Result := False;

  if not TryGetNodeData(ANodeIndex, D) then
  begin
    AClave := '__SINCLIENTE__';
    ACaption := '(sin cliente)';
    Exit(True);
  end;

  Cli := Trim(D.CodigoCliente);
  if Cli <> '' then
  begin
    AClave := 'CLI:' + Cli;
    // No hay tabla de nombres de cliente en el Planner: mostramos el codigo.
    // Cuando venga del ERP se podra enriquecer con la razon social.
    ACaption := Cli;
  end
  else
  begin
    AClave := '__SINCLIENTE__';
    ACaption := '(sin cliente)';
  end;
  Result := True;
end;

procedure TGanttControlClientes.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  // Solo lectura: cortamos el arranque de drag/resize anulando el nodo pulsado
  // antes de que el MouseMove del padre lo inicie (el resto -hover, panning,
  // seleccion- sigue funcionando via inherited).
  if ssLeft in Shift then
  begin
    FMouseDownNodeIndex := -1;
    FMouseDownOnHandle := nhNone;
  end;
  inherited MouseMove(Shift, X, Y);
end;

end.
