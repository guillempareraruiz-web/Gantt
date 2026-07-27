unit uWbsNivelacionDlg;

{
  Dialogo de NIVELACION DE RECURSOS (Modulo de Ingenieria, paradigma TAREAS).

  Ensena lo que la nivelacion PROPONE antes de tocar nada. La razon de que sea
  una previsualizacion y no una accion directa: nivelar puede mover decenas de
  tareas y retrasar la fecha de fin del proyecto. Aplicar eso sin ver la lista
  seria pedirle al usuario que se fie de una caja negra, y la primera vez que el
  resultado no le guste dejara de usar la funcion.

  Tres partes:
    1. Cabecera KPI    sobrecargas antes / despues, tareas movidas, retraso del
                       proyecto. Responde "me compensa?" de un vistazo.
    2. Opciones        el interruptor "solo dentro de la holgura" recalcula EN
                       VIVO: cambiarlo vuelve a nivelar y la lista se actualiza,
                       para poder comparar los dos escenarios antes de decidir.
    3. Grid            una fila por tarea movida: de cuando a cuando, cuanto se
                       retrasa y POR QUIEN espera. Sin esa ultima columna el
                       usuario ve un retraso sin saber a que se debe.

  Debajo, si los hay, los conflictos no resueltos: en modo "solo holgura" es
  normal que queden, y callarlos daria la falsa impresion de que todo esta bien.

  El dialogo NO escribe en BD ni recalcula el CPM: recibe una funcion de
  nivelacion que la vista le presta (OnNivelar) y devuelve la propuesta aceptada.
  Persistirla es responsabilidad de la vista, que es quien tiene el repo.

  Las unicas etiquetas que se crean por codigo son las TARJETAS KPI: su numero
  es fijo, pero su texto y su color cambian en cada renivelado, asi que se
  repintan sobre pnlKPI. Todo lo demas vive en el .dfm.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Math,
  System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Dialogs,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGrid, cxButtons, cxCheckBox, cxTextEdit, cxMemo,
  cxContainer, cxMaskEdit, cxDropDownEdit,
  dxSkinsCore, dxSkinsDefaultPainters,
  uWbsTypes, uWbsNivelacion;

type
  // La vista presta esta funcion: recalcula la propuesta con otras opciones.
  // Asi el dialogo puede ofrecer el interruptor de holgura sin conocer ni el
  // motor ni los datos del proyecto.
  TWbsNivelarFunc = function(const AOpciones: TWbsNivelacionOpciones)
    : TWbsNivelacionResult of object;

  TfrmWbsNivelacionDlg = class(TForm)
    pnlHeader: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlKPI: TPanel;
    pnlOpciones: TPanel;
    lblAviso: TLabel;
    chkSoloHolgura: TcxCheckBox;
    chkMoverIniciadas: TcxCheckBox;
    pnlBottom: TPanel;
    btnAplicar: TcxButton;
    btnCancelar: TcxButton;
    pnlConflictos: TPanel;
    lblConflictos: TLabel;
    memoConflictos: TcxMemo;
    grid: TcxGrid;
    tv: TcxGridTableView;
    colTarea: TcxGridColumn;
    colActual: TcxGridColumn;
    colNuevo: TcxGridColumn;
    colRetraso: TcxGridColumn;
    colMotivo: TcxGridColumn;
    lvl: TcxGridLevel;
    // Los manejadores del DFM van en la zona PUBLICADA (arriba de private): si
    // se declaran en private, el streaming del .dfm no los encuentra y el form
    // aborta con "Invalid property value" al abrirse.
    procedure OpcionesChanged(Sender: TObject);
  private
    FRes: TWbsNivelacionResult;
    FOpciones: TWbsNivelacionOpciones;
    FOnNivelar: TWbsNivelarFunc;
    FJornadaMin: Integer;
    FCargando: Boolean;

    procedure PintarTodo;
    procedure PintarKPI;
    procedure LlenarGrid;
    procedure LlenarConflictos;
    procedure TarjetaKPI(AX: Integer; const ARotulo, AValor: string;
      AColor: TColor);
    function TextoDias(AMin: Double): string;
  public
    // Devuelve True si el usuario acepta; ARes sale con la propuesta VIGENTE en
    // ese momento (puede no ser la inicial: el usuario ha podido cambiar las
    // opciones y renivelar).
    class function Execute(const ATitulo: string;
      const AInicial: TWbsNivelacionResult;
      const AOpcionesIniciales: TWbsNivelacionOpciones;
      ANivelar: TWbsNivelarFunc; AJornadaMin: Integer;
      out ARes: TWbsNivelacionResult;
      out AOpciones: TWbsNivelacionOpciones): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uHelpViewer;

const
  ANCHO_TARJETA = 165;

{ TfrmWbsNivelacionDlg }

class function TfrmWbsNivelacionDlg.Execute(const ATitulo: string;
  const AInicial: TWbsNivelacionResult;
  const AOpcionesIniciales: TWbsNivelacionOpciones;
  ANivelar: TWbsNivelarFunc; AJornadaMin: Integer;
  out ARes: TWbsNivelacionResult;
  out AOpciones: TWbsNivelacionOpciones): Boolean;
var
  F: TfrmWbsNivelacionDlg;
begin
  ARes := AInicial;
  AOpciones := AOpcionesIniciales;

  F := TfrmWbsNivelacionDlg.Create(nil);
  try
    F.FRes := AInicial;
    F.FOpciones := AOpcionesIniciales;
    F.FOnNivelar := ANivelar;
    F.FJornadaMin := AJornadaMin;
    if F.FJornadaMin <= 0 then F.FJornadaMin := 480;

    F.lblSubtitulo.Caption := ATitulo;

    // Ayuda contextual: el boton '?' del caption y F1. Sin esta llamada el
    // boton se dibuja (BorderIcons lo trae del .dfm) pero no hace nada.
    THelpViewer.InstallHelp(F, 'uWbsNivelacionDlg', 'Nivelar recursos');

    // Marcar los interruptores SIN disparar el renivelado: el OnChange del
    // cxCheckBox salta tambien al asignar Checked por codigo, y aqui todavia
    // no hay nada que recalcular (la propuesta inicial ya viene dada).
    F.FCargando := True;
    try
      F.chkSoloHolgura.Checked := AOpcionesIniciales.SoloDentroHolgura;
      F.chkMoverIniciadas.Checked := AOpcionesIniciales.MoverIniciadas;
    finally
      F.FCargando := False;
    end;

    F.PintarTodo;

    Result := F.ShowModal = mrOk;
    if Result then
    begin
      ARes := F.FRes;
      AOpciones := F.FOpciones;
    end;
  finally
    F.Free;
  end;
end;

function TfrmWbsNivelacionDlg.TextoDias(AMin: Double): string;
var
  D: Double;
begin
  if AMin <= 0 then Exit('-');
  D := AMin / FJornadaMin;
  if D < 1 then
    Result := Format('%.0f h', [AMin / 60])
  else if Frac(D) = 0 then
    Result := Format('%.0f d', [D])
  else
    Result := Format('%.1f d', [D]);
end;

procedure TfrmWbsNivelacionDlg.TarjetaKPI(AX: Integer;
  const ARotulo, AValor: string; AColor: TColor);
var
  L: TLabel;
begin
  L := TLabel.Create(pnlKPI);
  L.Parent := pnlKPI;
  L.SetBounds(AX, 8, ANCHO_TARJETA, 30);
  L.Font.Name := 'Segoe UI';
  L.Font.Size := 17;
  L.Font.Style := [fsBold];
  L.Font.Color := AColor;
  L.ParentFont := False;
  L.Caption := AValor;

  L := TLabel.Create(pnlKPI);
  L.Parent := pnlKPI;
  L.SetBounds(AX, 42, ANCHO_TARJETA, 16);
  L.Font.Name := 'Segoe UI';
  L.Font.Size := 8;
  L.Font.Color := clGray;
  L.ParentFont := False;
  L.Caption := ARotulo;
end;

procedure TfrmWbsNivelacionDlg.PintarKPI;
var
  X, I: Integer;
begin
  // Las tarjetas se recrean en cada repintado (renivelar cambia las cifras).
  for I := pnlKPI.ControlCount - 1 downto 0 do
    pnlKPI.Controls[I].Free;

  X := 16;
  TarjetaKPI(X, 'Sobrecargas antes',
    IntToStr(FRes.SobrecargasAntes), $000000CC);
  Inc(X, ANCHO_TARJETA);

  // La cifra que decide si la nivelacion sirve: si sigue igual, no ha resuelto
  // nada y hay que mirar los conflictos.
  if FRes.SobrecargasDespues = 0 then
    TarjetaKPI(X, 'Sobrecargas despu'#233's', '0', $00109010)
  else
    TarjetaKPI(X, 'Sobrecargas despu'#233's',
      IntToStr(FRes.SobrecargasDespues), $000080D0);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(X, 'Tareas que se mueven',
    IntToStr(Length(FRes.Retrasos)), $00595959);
  Inc(X, ANCHO_TARJETA);

  if FRes.RetrasoProyectoMin > 0 then
    TarjetaKPI(X, 'El proyecto se retrasa',
      '+' + TextoDias(FRes.RetrasoProyectoMin), $000000CC)
  else
    TarjetaKPI(X, 'El proyecto se retrasa', 'No', $00109010);
  Inc(X, ANCHO_TARJETA);

  if Length(FRes.Conflictos) > 0 then
    TarjetaKPI(X, 'Sin resolver',
      IntToStr(Length(FRes.Conflictos)), $000080D0)
  else
    TarjetaKPI(X, 'Sin resolver', '-', $00A0A0A0);
end;

procedure TfrmWbsNivelacionDlg.LlenarGrid;
var
  I: Integer;
begin
  tv.BeginUpdate;
  try
    tv.DataController.RecordCount := Length(FRes.Retrasos);
    for I := 0 to High(FRes.Retrasos) do
    begin
      tv.DataController.Values[I, colTarea.Index] :=
        FRes.Retrasos[I].Caption;
      tv.DataController.Values[I, colActual.Index] :=
        FormatDateTime('dd/mm/yyyy hh:nn', FRes.Retrasos[I].InicioActual);
      tv.DataController.Values[I, colNuevo.Index] :=
        FormatDateTime('dd/mm/yyyy hh:nn', FRes.Retrasos[I].InicioNuevo);
      tv.DataController.Values[I, colRetraso.Index] :=
        TextoDias(FRes.Retrasos[I].RetrasoMin);
      tv.DataController.Values[I, colMotivo.Index] :=
        FRes.Retrasos[I].MotivoNombres;
    end;
  finally
    tv.EndUpdate;
  end;
end;

procedure TfrmWbsNivelacionDlg.LlenarConflictos;
var
  I: Integer;
begin
  memoConflictos.Lines.BeginUpdate;
  try
    memoConflictos.Lines.Clear;
    for I := 0 to High(FRes.Conflictos) do
      if Trim(FRes.Conflictos[I].Nombre) <> '' then
        memoConflictos.Lines.Add(Format('%s  ' + #$2022 + '  %s  (%s)',
          [FRes.Conflictos[I].Caption, FRes.Conflictos[I].Motivo,
           FRes.Conflictos[I].Nombre]))
      else
        memoConflictos.Lines.Add(Format('%s  ' + #$2022 + '  %s',
          [FRes.Conflictos[I].Caption, FRes.Conflictos[I].Motivo]));
  finally
    memoConflictos.Lines.EndUpdate;
  end;

  // Si no hay conflictos, el bloque entero sobra: dejarlo vacio ocupando
  // espacio sugiere que falta algo por cargar. Al ocultar el panel (alBottom),
  // el grid (alClient) recupera su hueco solo.
  pnlConflictos.Visible := Length(FRes.Conflictos) > 0;
  if pnlConflictos.Visible then
    lblConflictos.Caption := Format(
      'Sin resolver (%d): estas tareas no se han podido mover',
      [Length(FRes.Conflictos)]);
end;

procedure TfrmWbsNivelacionDlg.PintarTodo;
begin
  PintarKPI;
  LlenarGrid;
  LlenarConflictos;

  if Length(FRes.Retrasos) = 0 then
  begin
    if FRes.SobrecargasAntes = 0 then
      lblAviso.Caption :=
        'No hay ninguna sobreasignaci'#243'n que resolver: nadie supera su jornada.'
    else
      lblAviso.Caption :=
        'No se ha podido mover ninguna tarea con estas opciones. ' +
        'Pruebe a desmarcar "s'#243'lo dentro de la holgura".';
  end
  else if FRes.SobrecargasDespues > 0 then
    lblAviso.Caption := Format(
      'Quedan %d tramo(s) sobreasignados tras nivelar. ' +
      'Rev'#237'selos en el bloque inferior.', [FRes.SobrecargasDespues])
  else
    lblAviso.Caption :=
      'La propuesta resuelve todas las sobreasignaciones.';

  // Sin nada que aplicar, el boton no debe invitar a pulsarlo.
  btnAplicar.Enabled := Length(FRes.Retrasos) > 0;
end;

procedure TfrmWbsNivelacionDlg.OpcionesChanged(Sender: TObject);
var
  Cur: TCursor;
begin
  // El OnChange del cxCheckBox tambien salta al asignar Checked por codigo.
  if FCargando then Exit;
  if not Assigned(FOnNivelar) then Exit;

  FCargando := True;
  Cur := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    FOpciones.SoloDentroHolgura := chkSoloHolgura.Checked;
    FOpciones.MoverIniciadas := chkMoverIniciadas.Checked;
    FRes := FOnNivelar(FOpciones);
    PintarTodo;
  finally
    Screen.Cursor := Cur;
    FCargando := False;
  end;
end;

end.
