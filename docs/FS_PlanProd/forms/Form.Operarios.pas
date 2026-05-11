unit Form.Operarios;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids;

type
  TfrmOperarios = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    pnlClient: TPanel;
    sgOperarios: TStringGrid;
    pnlDetalle: TPanel;
    gbDatos: TGroupBox;
    lblCodigo: TLabel;
    edtCodigo: TEdit;
    lblNombre: TLabel;
    edtNombre: TEdit;
    lblSueldo: TLabel;
    edtSueldo: TEdit;
    lblRecargoNoche: TLabel;
    edtRecargoNoche: TEdit;
    lblRecargoFestivo: TLabel;
    edtRecargoFestivo: TEdit;
    lblTurno: TLabel;
    cbTurno: TComboBox;
    lblHoraIni: TLabel;
    seHoraIni: TEdit;
    lblHoraFin: TLabel;
    seHoraFin: TEdit;
    gbHabilidades: TGroupBox;
    sgHabilidades: TStringGrid;
    btnAddHab: TButton;
    btnDelHab: TButton;
    gbCentros: TGroupBox;
    clbCentros: TCheckListBox;
    btnGuardar: TButton;
    btnCancelar: TButton;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure sgOperariosClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnAddHabClick(Sender: TObject);
    procedure btnDelHabClick(Sender: TObject);
  private
    FIdxSeleccionado: Integer;
    procedure RefrescarGrid;
    procedure CargarDetalle(AIdx: Integer);
    procedure GuardarDetalle;
    procedure InitGridHabilidades;
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils,
  System.Math,
  System.Generics.Collections,
  FS.PlanProd.Types,
  FS.PlanProd.SessionData;

procedure TfrmOperarios.FormCreate(Sender: TObject);
var
  LCods: TArray<string>;
  I: Integer;
begin
  FIdxSeleccionado := -1;

  // Cabeceras del grid de operarios
  sgOperarios.ColCount := 7;
  sgOperarios.RowCount := 1;
  sgOperarios.Cells[0, 0] := 'Código';
  sgOperarios.Cells[1, 0] := 'Nombre';
  sgOperarios.Cells[2, 0] := 'Turno';
  sgOperarios.Cells[3, 0] := 'Horario';
  sgOperarios.Cells[4, 0] := '€/h';
  sgOperarios.Cells[5, 0] := 'Habilidades';
  sgOperarios.Cells[6, 0] := 'Estado';
  sgOperarios.ColWidths[0] := 60;
  sgOperarios.ColWidths[1] := 130;
  sgOperarios.ColWidths[2] := 70;
  sgOperarios.ColWidths[3] := 80;
  sgOperarios.ColWidths[4] := 50;
  sgOperarios.ColWidths[5] := 60;
  sgOperarios.ColWidths[6] := 80;

  cbTurno.Items.Clear;
  cbTurno.Items.Add('Mañana');
  cbTurno.Items.Add('Tarde');
  cbTurno.Items.Add('Noche');
  cbTurno.Items.Add('Partido');
  cbTurno.Items.Add('Central');

  // Cargar lista de centros
  LCods := Session.Catalogo.ListaCodCentros;
  clbCentros.Items.Clear;
  for I := 0 to High(LCods) do
    clbCentros.Items.Add(LCods[I]);

  InitGridHabilidades;
  RefrescarGrid;
  if Session.Operarios.Count > 0 then
  begin
    sgOperarios.Row := 1;
    CargarDetalle(0);
  end;
end;

procedure TfrmOperarios.InitGridHabilidades;
begin
  sgHabilidades.ColCount := 2;
  sgHabilidades.RowCount := 2;
  sgHabilidades.Cells[0, 0] := 'Habilidad';
  sgHabilidades.Cells[1, 0] := 'Nivel (0-3)';
  sgHabilidades.ColWidths[0] := 200;
  sgHabilidades.ColWidths[1] := 80;
  sgHabilidades.FixedRows := 1;
  sgHabilidades.Options := sgHabilidades.Options + [goEditing, goAlwaysShowEditor];
end;

procedure TfrmOperarios.RefrescarGrid;
var
  I: Integer;
  LOp: TOperario;
  LEstado: string;
begin
  sgOperarios.RowCount := Max(2, Session.Operarios.Count + 1);

  for I := 0 to Session.Operarios.Count - 1 do
  begin
    LOp := Session.Operarios[I];
    sgOperarios.Cells[0, I + 1] := LOp.CodOperario;
    sgOperarios.Cells[1, I + 1] := LOp.Nombre;
    sgOperarios.Cells[2, I + 1] := LOp.Turno.NombreLargo;
    sgOperarios.Cells[3, I + 1] := Format('%d-%dh',
      [LOp.Turno.HoraInicio, LOp.Turno.HoraFin]);
    sgOperarios.Cells[4, I + 1] := FormatFloat('0.00', LOp.SueldoEurHora);
    if LOp.Habilidades <> nil then
      sgOperarios.Cells[5, I + 1] := IntToStr(LOp.Habilidades.Count)
    else
      sgOperarios.Cells[5, I + 1] := '0';

    if LOp.EstaAusenteEn(Session.FechaSimulada) then
      LEstado := 'AUSENTE'
    else if not LOp.EstaEnTurnoEn(Session.FechaSimulada) then
      LEstado := 'F.TURNO'
    else if LOp.Estado = esOcupado then
      LEstado := 'OCUPADO'
    else
      LEstado := 'LIBRE';
    sgOperarios.Cells[6, I + 1] := LEstado;
  end;

  // Limpiar fila vacía si toca
  if Session.Operarios.Count = 0 then
  begin
    sgOperarios.Cells[0, 1] := '';
    sgOperarios.Cells[1, 1] := '';
  end;
end;

procedure TfrmOperarios.sgOperariosClick(Sender: TObject);
var
  LRow: Integer;
begin
  LRow := sgOperarios.Row;
  if (LRow >= 1) and (LRow - 1 < Session.Operarios.Count) then
    CargarDetalle(LRow - 1);
end;

procedure TfrmOperarios.CargarDetalle(AIdx: Integer);
var
  LOp: TOperario;
  LCentro: string;
  I, LRow: Integer;
  LPair: TPair<string, TNivelCompetencia>;
  LCods: TArray<string>;
begin
  FIdxSeleccionado := AIdx;
  LOp := Session.Operarios[AIdx];

  edtCodigo.Text := LOp.CodOperario;
  edtNombre.Text := LOp.Nombre;
  edtSueldo.Text := FormatFloat('0.00', LOp.SueldoEurHora);
  edtRecargoNoche.Text := FormatFloat('0.00', LOp.RecargoTurnoNoche);
  edtRecargoFestivo.Text := FormatFloat('0.00', LOp.RecargoFestivo);

  case LOp.Turno.Tipo of
    ttManana: cbTurno.ItemIndex := 0;
    ttTarde: cbTurno.ItemIndex := 1;
    ttNoche: cbTurno.ItemIndex := 2;
    ttPartido: cbTurno.ItemIndex := 3;
    ttCentral: cbTurno.ItemIndex := 4;
  end;
  seHoraIni.Text := IntToStr(LOp.Turno.HoraInicio);
  seHoraFin.Text := IntToStr(LOp.Turno.HoraFin);

  // Centros
  for I := 0 to clbCentros.Items.Count - 1 do
  begin
    LCentro := clbCentros.Items[I];
    clbCentros.Checked[I] := LOp.PuedeTrabajarEnCentro(LCentro);
  end;

  // Habilidades
  sgHabilidades.RowCount := 2;
  for I := 1 to sgHabilidades.RowCount - 1 do
  begin
    sgHabilidades.Cells[0, I] := '';
    sgHabilidades.Cells[1, I] := '';
  end;

  if (LOp.Habilidades <> nil) and (LOp.Habilidades.Count > 0) then
  begin
    sgHabilidades.RowCount := LOp.Habilidades.Count + 1;
    LRow := 1;
    for LPair in LOp.Habilidades do
    begin
      sgHabilidades.Cells[0, LRow] := LPair.Key;
      sgHabilidades.Cells[1, LRow] := IntToStr(LPair.Value);
      Inc(LRow);
    end;
  end;
end;

procedure TfrmOperarios.GuardarDetalle;
var
  LOp: TOperario;
  I, LNivel: Integer;
  LCentro, LHab: string;
  LFmt: TFormatSettings;
  LSueldo, LRecNoche, LRecFest: Double;
begin
  if (FIdxSeleccionado < 0) or
    (FIdxSeleccionado >= Session.Operarios.Count) then
    Exit;

  LOp := Session.Operarios[FIdxSeleccionado];

  LOp.Nombre := edtNombre.Text;

  LFmt := FormatSettings;
  LFmt.DecimalSeparator := '.';
  if TryStrToFloat(StringReplace(edtSueldo.Text, ',', '.', [rfReplaceAll]),
    LSueldo, LFmt) then
    LOp.SueldoEurHora := LSueldo;
  if TryStrToFloat(StringReplace(edtRecargoNoche.Text, ',', '.',
    [rfReplaceAll]), LRecNoche, LFmt) then
    LOp.RecargoTurnoNoche := LRecNoche;
  if TryStrToFloat(StringReplace(edtRecargoFestivo.Text, ',', '.',
    [rfReplaceAll]), LRecFest, LFmt) then
    LOp.RecargoFestivo := LRecFest;

  case cbTurno.ItemIndex of
    0:
      begin
        LOp.Turno.Tipo := ttManana;
        LOp.Turno.CodTurno := 'M';
      end;
    1:
      begin
        LOp.Turno.Tipo := ttTarde;
        LOp.Turno.CodTurno := 'T';
      end;
    2:
      begin
        LOp.Turno.Tipo := ttNoche;
        LOp.Turno.CodTurno := 'N';
      end;
    3:
      begin
        LOp.Turno.Tipo := ttPartido;
        LOp.Turno.CodTurno := 'P';
      end;
    4:
      begin
        LOp.Turno.Tipo := ttCentral;
        LOp.Turno.CodTurno := 'C';
      end;
  end;
  LOp.Turno.HoraInicio := StrToIntDef(seHoraIni.Text, 9);
  LOp.Turno.HoraFin := StrToIntDef(seHoraFin.Text, 18);

  // Centros: limpiar y repoblar
  if LOp.CentrosHabilitados = nil then
    LOp.Init;
  LOp.CentrosHabilitados.Clear;
  for I := 0 to clbCentros.Items.Count - 1 do
  begin
    if clbCentros.Checked[I] then
    begin
      LCentro := clbCentros.Items[I];
      LOp.CentrosHabilitados.Add(LCentro);
    end;
  end;

  // Habilidades: limpiar y repoblar
  if LOp.Habilidades = nil then
    LOp.Init;
  LOp.Habilidades.Clear;
  for I := 1 to sgHabilidades.RowCount - 1 do
  begin
    LHab := Trim(sgHabilidades.Cells[0, I]);
    if LHab <> '' then
    begin
      LNivel := StrToIntDef(sgHabilidades.Cells[1, I], 1);
      if LNivel < 0 then LNivel := 0;
      if LNivel > 3 then LNivel := 3;
      LOp.Habilidades.AddOrSetValue(LHab, LNivel);
    end;
  end;

  Session.Operarios[FIdxSeleccionado] := LOp;
  RefrescarGrid;
end;

procedure TfrmOperarios.btnGuardarClick(Sender: TObject);
begin
  GuardarDetalle;
  ShowMessage('Operario actualizado.');
end;

procedure TfrmOperarios.btnCancelarClick(Sender: TObject);
begin
  if FIdxSeleccionado >= 0 then
    CargarDetalle(FIdxSeleccionado);
end;

procedure TfrmOperarios.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmOperarios.btnAddHabClick(Sender: TObject);
begin
  sgHabilidades.RowCount := sgHabilidades.RowCount + 1;
  sgHabilidades.Cells[0, sgHabilidades.RowCount - 1] := 'NUEVA_HAB';
  sgHabilidades.Cells[1, sgHabilidades.RowCount - 1] := '1';
  sgHabilidades.Row := sgHabilidades.RowCount - 1;
end;

procedure TfrmOperarios.btnDelHabClick(Sender: TObject);
var
  I: Integer;
begin
  if sgHabilidades.Row < 1 then Exit;
  if sgHabilidades.RowCount <= 2 then
  begin
    sgHabilidades.Cells[0, 1] := '';
    sgHabilidades.Cells[1, 1] := '';
    Exit;
  end;
  for I := sgHabilidades.Row to sgHabilidades.RowCount - 2 do
  begin
    sgHabilidades.Cells[0, I] := sgHabilidades.Cells[0, I + 1];
    sgHabilidades.Cells[1, I] := sgHabilidades.Cells[1, I + 1];
  end;
  sgHabilidades.RowCount := sgHabilidades.RowCount - 1;
end;

end.
