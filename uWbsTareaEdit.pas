unit uWbsTareaEdit;

{
  Ficha de una TAREA de proyecto (modulo de Ingenieria). Fase 3.

  Se abre con doble clic sobre una fila del grid WBS o sobre una barra del
  Gantt. Dos pestanas:

    TAREA     - Estado, prioridad, etiqueta, fechas, duracion estimada
                (dias/horas/minutos), esfuerzo, tiempo invertido y notas.
    OPERARIOS - Personas asignadas, con su % de dedicacion y las horas
                imputadas a cada una.

  Modelo de datos (V080): la ficha vive en FS_PL_TaskDetail y las asignaciones
  en FS_PL_TaskOperario, NO en FS_PL_NodeData. NodeData describe una operacion
  de produccion (OF, articulo, centro, cantidades); una tarea de ingenieria
  comparte el NODO pero no esos atributos.

  Reglas que no son obvias:
  - El % de avance NO se edita: es un derivado (invertido / duracion) y se
    recalcula en vivo mientras se teclea.
  - Editar la fecha de inicio equivale a fijar una RESTRICCION del motor
    (ConstraintKind = 2, fecha fija). Si no, el siguiente recalculo del CPM
    machacaria la fecha que acaba de escribir el usuario.
  - Los resumenes no llegan aqui: su duracion y avance son agregados.

  Sin .dfm: se construye por codigo (mismo patron que TfrmRowFilterDialog).
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  System.Variants, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Graphics, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs,
  cxTextEdit, cxButtons, cxContainer, cxEdit, cxMemo, cxDropDownEdit,
  cxCalendar, cxSpinEdit, cxMaskEdit, cxCheckBox,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData,
  cxGrid, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxClasses, cxDataStorage,
  uWbsTypes;

type
  // Un operario disponible para asignar (catalogo).
  TWbsOperarioItem = record
    OperatorId: Integer;
    Nombre: string;
  end;
  TWbsOperarioItems = TArray<TWbsOperarioItem>;

  // Alta de una etiqueta en el catalogo. La ficha no habla con la BD: pide a
  // la vista que la cree y le devuelva el TagId real.
  TWbsNuevoTagEvent = function(const ATag: TWbsTag): Integer of object;

  // Todo lo que la ficha edita, en un solo sitio: simplifica la llamada y deja
  // claro que entra y que sale.
  TWbsTareaEditData = record
    NodeId: Integer;
    Caption: string;
    // Tipo de tarea (tarea / resumen / hito). Editable: cambiarlo altera lo
    // que calcula el motor, por eso el dialogo bloquea los campos que dejan de
    // tener sentido.
    Kind: TWbsTaskKind;
    EsHito: Boolean;   // atajo de Kind = wtkHito, para no repetirlo

    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    DuracionMin: Double;
    MinutosInvertidos: Double;

    // --- Triada de esfuerzo (V082) -------------------------------------------
    TrabajoMin: Double;
    TipoTarea: TWbsTipoTarea;
    // Unidades vigentes (suma de dedicaciones / 100). Entra con lo que hay en
    // BD y sale recalculada si el usuario toca la pestana de operarios.
    Unidades: Double;

    // Restriccion de fecha, juego completo de MS Project (V082). Sustituye al
    // apano de "editar el inicio = fecha fija": ahora se elige explicitamente.
    ConstraintKind: Integer;
    ConstraintDate: TDateTime;

    Detail: TWbsTaskDetail;
    Operarios: TWbsTaskOperarioArray;
    // Catalogo de etiquetas con Asignada marcada para esta tarea (V081).
    Tags: TWbsTagArray;

    // Salida: True si el usuario cambio la fecha de inicio a mano, para que la
    // vista fije la restriccion de fecha fija en el motor.
    FechaInicioEditada: Boolean;
  end;

  TfrmWbsTareaEdit = class(TForm)
  private
    FPages: TPageControl;
    FTabTarea: TTabSheet;
    FTabTiempo: TTabSheet;      // fechas, restriccion y esfuerzo (V082)
    FTabOperarios: TTabSheet;
    FTabNotas: TTabSheet;

    // --- Cabecera ---
    FLblTarea: TLabel;
    FLblAvanceValor: TLabel;
    // Rotulo bajo la cifra: sin el, un "56 %" suelto no dice de que es.
    FLblAvanceRotulo: TLabel;

    // --- Tab Tarea ---
    FCbTipo: TcxComboBox;
    FLblAvisoTipo: TLabel;
    FCbEstado: TcxComboBox;
    FCbPrioridad: TcxComboBox;
    // Chips de etiquetas (estilo Trello): un TPanel por etiqueta del catalogo,
    // clicable para asignarla o quitarla. Las no asignadas se pintan apagadas.
    FPnlTags: TPanel;
    FChips: TList<TPanel>;
    FLblEtiquetas: TLabel;
    // Y donde arranca el bloque de etiquetas: los controles de debajo se
    // reubican cuando los chips ocupan mas de una linea.
    FYTrasTags: Integer;
    FEdInicio: TcxDateEdit;
    FEdFin: TcxDateEdit;
    FEdDias: TcxSpinEdit;
    FEdHoras: TcxSpinEdit;
    FEdMinutos: TcxSpinEdit;
    FEdEsfuerzo: TcxSpinEdit;
    FEdInvertido: TcxSpinEdit;
    FMemoNotas: TcxMemo;
    FLblAviso: TLabel;

    // --- Triada de esfuerzo (V082) -------------------------------------------
    // Trabajo = Duracion x Unidades. FCbTipoTarea decide cual de las tres se
    // despeja al tocar las otras; FLblUnidades muestra las unidades vigentes
    // (suma de dedicaciones de la pestana Operarios), que no se teclean aqui.
    FCbTipoTarea: TcxComboBox;
    FEdTrabajo: TcxSpinEdit;
    FLblUnidades: TLabel;
    FLblEcuacion: TLabel;
    // Restriccion de fecha (juego completo de MS Project, V082).
    FCbRestriccion: TcxComboBox;
    FEdFechaRestr: TcxDateEdit;
    FLblAvisoRestr: TLabel;

    // --- Tab Operarios ---
    // cxGrid en vez de TcxCheckListBox: aquel codifica el marcado en la
    // propiedad EditValue como mascara de bits y revienta con mas de 64 items
    // ("The number of items cannot be greater than 64"), que es justo lo que
    // pasa con el catalogo completo de operarios. Ademas el grid es el patron
    // del proyecto para multiseleccion (ver uAssignOperaris).
    FGridOperarios: TcxGrid;
    FLvlOperarios: TcxGridLevel;
    FTvOperarios: TcxGridTableView;
    FColSel: TcxGridColumn;
    FColNombre: TcxGridColumn;
    FColDedic: TcxGridColumn;
    FColHoras: TcxGridColumn;
    // KPIs al pie de la pestana: resumen de lo marcado en el grid.
    FPnlKpiOper: TPanel;
    FLblKpiOperarios: TLabel;
    FLblKpiDedicacion: TLabel;
    FLblKpiHoras: TLabel;
    FLblKpiTrabajo: TLabel;

    FData: TWbsTareaEditData;
    FTags: TWbsTagArray;      // copia de trabajo: los chips la modifican
    FOnNuevoTag: TWbsNuevoTagEvent;
    FCatalogo: TWbsOperarioItems;
    FJornadaMin: Integer;
    FInicioOriginal: TDateTime;
    FCargando: Boolean;

    procedure BuildUI;
    procedure BuildTabTarea;
    procedure BuildTabTiempo;
    procedure BuildTabOperarios;
    procedure BuildTabNotas;
    // Titulo de bloque dentro de una pestana (negrita + linea separadora).
    // Devuelve la Y siguiente, ya con el aire de separacion aplicado.
    function TituloBloque(AParent: TWinControl; AY: Integer;
      const ACaption: string; APrimero: Boolean = False): Integer;
    // Empuja los controles que van debajo de las etiquetas cuando los chips
    // ocupan mas de una linea (si no, se solapan con el campo Inicio).
    procedure ReubicarTrasTags;
    procedure CargarDatos;
    procedure VolcarDatos;

    procedure DoDuracionChange(Sender: TObject);
    procedure DoInvertidoChange(Sender: TObject);
    procedure DoTipoChange(Sender: TObject);
    // Triada: al tocar duracion o trabajo se recalcula la otra magnitud segun
    // el tipo de tarea, y se refresca la linea que explica la ecuacion.
    procedure DoTrabajoChange(Sender: TObject);
    procedure DoTipoTareaChange(Sender: TObject);
    procedure AplicarTriada(ACampo: TWbsCampoEditado);
    procedure RefrescarEcuacion;
    // Restriccion: la fecha solo tiene sentido en las que atan a una fecha.
    procedure DoRestriccionChange(Sender: TObject);
    procedure AplicarRestriccion;
    // Habilita o bloquea los campos segun el tipo elegido (un hito no dura, un
    // resumen se calcula a partir de sus hijos).
    procedure AplicarTipo;
    procedure RefrescarAvance;
    // Etiquetas: pinta un chip por etiqueta del catalogo y alterna su estado
    // al hacer clic.
    procedure ConstruirChips;
    procedure PintarChip(AChip: TPanel; const ATag: TWbsTag);
    procedure DoChipClick(Sender: TObject);
    procedure DoNuevoTag(Sender: TObject);
    function DuracionEditadaMin: Double;

    function LabelEn(AParent: TWinControl; AX, AY: Integer;
      const ACaption: string; AAncho: Integer = 120): TLabel;
    // Tarjeta de KPI: cifra grande arriba y rotulo pequeno debajo. Devuelve el
    // label de la CIFRA, que es el que se refresca.
    function KpiEn(AParent: TWinControl; AX: Integer;
      const ARotulo: string): TLabel;
    // Recalcula los KPIs del pie a partir de lo que hay marcado en el grid.
    procedure RefrescarKpiOperarios;
    // El grid ha cambiado (marcado o dedicacion): refrescar KPIs.
    procedure DoOperariosChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
  public
    // ACatalogo = operarios disponibles para asignar. ADatos entra con los
    // valores actuales y sale con los editados.
    class function Execute(var ADatos: TWbsTareaEditData;
      const ACatalogo: TWbsOperarioItems;
      ANuevoTag: TWbsNuevoTagEvent = nil;
      const AJornadaMin: Integer = 480): Boolean;
  end;

implementation

const
  // Paleta de partida para etiquetas nuevas (BGR). Se va rotando segun cuantas
  // haya, para que dos etiquetas seguidas no salgan del mismo color.
  COLORES_TAG: array[0..5] of TColor = (
    $004242DF,   // rojo suave
    $002F7BEF,   // naranja
    $00C89A18,   // azul
    $005AAE6B,   // verde
    $00B06AA8,   // morado
    $00999999    // gris
  );

  MARGEN    = 16;
  // Alto de una fila de formulario. Con 30 los controles de 22 px quedaban a
  // 8 px unos de otros y la ficha se leia como un muro: 34 da el aire justo
  // para distinguir una fila de la siguiente sin que la pestana crezca de mas.
  ALTO_FILA = 34;
  ANCHO_ETQ = 130;
  ANCHO_ED  = 150;
  // Ancho de las notas grises que acompanan a un campo ("horas previstas al
  // abrir la tarea", la ecuacion del esfuerzo...). Antes eran anchos sueltos
  // por control y la mas larga salia CORTADA por el borde de la ficha.
  ANCHO_NOTA = 330;
  // Separacion extra ANTES del titulo de un bloque, para que se lea como una
  // seccion y no como una fila mas.
  SEP_BLOQUE = 14;

class function TfrmWbsTareaEdit.Execute(var ADatos: TWbsTareaEditData;
  const ACatalogo: TWbsOperarioItems; ANuevoTag: TWbsNuevoTagEvent;
  const AJornadaMin: Integer): Boolean;
var
  F: TfrmWbsTareaEdit;
begin
  F := TfrmWbsTareaEdit.CreateNew(nil);
  try
    F.FData := ADatos;
    F.FTags := Copy(ADatos.Tags);
    F.FCatalogo := ACatalogo;
    F.FOnNuevoTag := ANuevoTag;
    F.FChips := TList<TPanel>.Create;
    F.FJornadaMin := AJornadaMin;
    if F.FJornadaMin <= 0 then F.FJornadaMin := 480;
    F.FInicioOriginal := ADatos.FechaInicio;

    F.BuildUI;
    F.CargarDatos;

    Result := F.ShowModal = mrOk;
    if Result then
    begin
      F.VolcarDatos;
      ADatos := F.FData;
    end;
  finally
    F.FChips.Free;
    F.Free;
  end;
end;

function TfrmWbsTareaEdit.LabelEn(AParent: TWinControl; AX, AY: Integer;
  const ACaption: string; AAncho: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(AX, AY + 4, AAncho, 20);
  Result.Caption := ACaption;
  Result.Font.Color := $00595959;
end;

procedure TfrmWbsTareaEdit.BuildUI;
var
  Pnl, PnlAvance: TPanel;
  BtnOK, BtnCancel: TcxButton;
begin
  BorderStyle := bsSizeable;
  Position := poScreenCenter;
  Caption := 'Ficha de tarea';
  // Se ensancha para que quepa la nota mas larga (la ecuacion del esfuerzo)
  // sin recortar. El alto baja respecto a la version anterior porque el bloque
  // de planificacion se ha ido a su propia pestana (ver BuildUI).
  ClientWidth := 720;
  ClientHeight := 560;
  Constraints.MinWidth := 660;
  Constraints.MinHeight := 520;
  Color := clWhite;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  // --- Cabecera: nombre de la tarea + avance ---
  Pnl := TPanel.Create(Self);
  Pnl.Parent := Self;
  Pnl.Align := alTop;
  Pnl.Height := 60;
  Pnl.BevelOuter := bvNone;
  Pnl.Color := $00F7F7F7;
  Pnl.ParentBackground := False;

  // Bloque del avance: cifra grande + rotulo debajo. El rotulo hace falta
  // porque un "56 %" suelto en una esquina no dice de QUE es el porcentaje
  // (nadie adivina que es tiempo invertido sobre duracion estimada).
  PnlAvance := TPanel.Create(Self);
  PnlAvance.Parent := Pnl;
  PnlAvance.Align := alRight;
  PnlAvance.Width := 130;
  PnlAvance.BevelOuter := bvNone;
  PnlAvance.Color := $00F7F7F7;
  PnlAvance.ParentBackground := False;

  // OJO: AutoSize := False DESPUES de fijar Caption y fuente, y Align en vez de
  // SetBounds+Anchors. Con SetBounds sobre un panel que aun no tiene su ancho
  // final, el label quedaba de 0 px y el texto no se veia.
  FLblAvanceValor := TLabel.Create(Self);
  FLblAvanceValor.Parent := PnlAvance;
  FLblAvanceValor.Align := alTop;
  FLblAvanceValor.AlignWithMargins := True;
  FLblAvanceValor.Margins.SetBounds(0, 8, MARGEN, 0);
  FLblAvanceValor.Font.Style := [fsBold];
  FLblAvanceValor.Font.Size := 13;
  FLblAvanceValor.Alignment := taRightJustify;
  FLblAvanceValor.AutoSize := False;
  FLblAvanceValor.Height := 24;

  FLblAvanceRotulo := TLabel.Create(Self);
  FLblAvanceRotulo.Parent := PnlAvance;
  FLblAvanceRotulo.Align := alTop;
  FLblAvanceRotulo.AlignWithMargins := True;
  FLblAvanceRotulo.Margins.SetBounds(0, 0, MARGEN, 0);
  FLblAvanceRotulo.Font.Size := 8;
  FLblAvanceRotulo.Font.Color := clGray;
  FLblAvanceRotulo.Alignment := taRightJustify;
  FLblAvanceRotulo.AutoSize := False;
  FLblAvanceRotulo.Height := 16;
  FLblAvanceRotulo.Caption := 'avance';
  FLblAvanceRotulo.ShowHint := True;
  FLblAvanceRotulo.Hint :=
    'Tiempo invertido sobre la duraci'#243'n estimada.';

  FLblTarea := TLabel.Create(Self);
  FLblTarea.Parent := Pnl;
  FLblTarea.Align := alClient;
  FLblTarea.AlignWithMargins := True;
  FLblTarea.Margins.SetBounds(MARGEN, 12, 8, 8);
  FLblTarea.Font.Style := [fsBold];
  FLblTarea.Font.Size := 11;
  FLblTarea.Layout := tlCenter;
  FLblTarea.AutoSize := False;
  FLblTarea.EllipsisPosition := epEndEllipsis;

  // --- Botonera inferior ---
  Pnl := TPanel.Create(Self);
  Pnl.Parent := Self;
  Pnl.Align := alBottom;
  Pnl.Height := 48;
  Pnl.BevelOuter := bvNone;
  Pnl.Color := clWhite;
  Pnl.ParentBackground := False;

  BtnCancel := TcxButton.Create(Self);
  BtnCancel.Parent := Pnl;
  BtnCancel.SetBounds(ClientWidth - MARGEN - 90, 10, 90, 28);
  BtnCancel.Caption := 'Cancelar';
  BtnCancel.ModalResult := mrCancel;
  BtnCancel.Cancel := True;
  BtnCancel.Anchors := [akTop, akRight];

  BtnOK := TcxButton.Create(Self);
  BtnOK.Parent := Pnl;
  BtnOK.SetBounds(ClientWidth - MARGEN - 188, 10, 90, 28);
  BtnOK.Caption := 'Aceptar';
  BtnOK.ModalResult := mrOk;
  BtnOK.Default := True;
  BtnOK.Anchors := [akTop, akRight];

  // --- Pestanas ---
  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;

  FTabTarea := TTabSheet.Create(Self);
  FTabTarea.PageControl := FPages;
  FTabTarea.Caption := 'Tarea';

  // TIEMPO en su propia pestana: la ficha intentaba hacer dos cosas a la vez,
  // IDENTIFICAR la tarea (tipo, estado, prioridad, etiquetas) y PLANIFICARLA
  // (fechas, restriccion, duracion, trabajo, tiempo invertido). Con la triada
  // de esfuerzo y las restricciones completas (V082) el bloque de planificacion
  // paso de tres filas a nueve y la pestana se leia como un muro. Separarlas
  // ademas agrupa lo que se consulta junto: quien mira las fechas no suele
  // estar cambiando el estado ni las etiquetas.
  FTabTiempo := TTabSheet.Create(Self);
  FTabTiempo.PageControl := FPages;
  FTabTiempo.Caption := 'Tiempo';

  FTabOperarios := TTabSheet.Create(Self);
  FTabOperarios.PageControl := FPages;
  FTabOperarios.Caption := 'Operarios';

  // Los comentarios van en su propia pestana: ocupaban media ficha y dejaban
  // sin sitio a las etiquetas, que necesitan crecer en varias lineas.
  FTabNotas := TTabSheet.Create(Self);
  FTabNotas.PageControl := FPages;
  FTabNotas.Caption := 'Comentarios';

  BuildTabTarea;
  BuildTabTiempo;
  BuildTabOperarios;
  BuildTabNotas;
end;

procedure TfrmWbsTareaEdit.BuildTabNotas;
begin
  FMemoNotas := TcxMemo.Create(Self);
  FMemoNotas.Parent := FTabNotas;
  FMemoNotas.Align := alClient;
  FMemoNotas.AlignWithMargins := True;
  FMemoNotas.Margins.SetBounds(MARGEN, MARGEN, MARGEN, MARGEN);
  FMemoNotas.Properties.ScrollBars := ssVertical;
  FMemoNotas.Properties.WordWrap := True;
end;

procedure TfrmWbsTareaEdit.BuildTabTarea;
var
  Y, X2: Integer;
begin
  Y := MARGEN;
  X2 := MARGEN + ANCHO_ETQ + ANCHO_ED + 30;

  // ======================= Clasificacion ==================================
  Y := TituloBloque(FTabTarea, Y, 'Clasificaci'#243'n', True);

  // --- Tipo de tarea ---
  LabelEn(FTabTarea, MARGEN, Y, 'Tipo');
  FCbTipo := TcxComboBox.Create(Self);
  FCbTipo.Parent := FTabTarea;
  FCbTipo.SetBounds(MARGEN + ANCHO_ETQ, Y, ANCHO_ED, 22);
  FCbTipo.Properties.DropDownListStyle := lsFixedList;
  FCbTipo.Properties.Items.Add('Tarea');
  FCbTipo.Properties.Items.Add('Resumen');
  FCbTipo.Properties.Items.Add('Hito');
  FCbTipo.Properties.OnChange := DoTipoChange;

  FLblAvisoTipo := LabelEn(FTabTarea, MARGEN + ANCHO_ETQ + ANCHO_ED + 12, Y,
    '', 260);
  FLblAvisoTipo.Font.Color := clGray;
  Inc(Y, ALTO_FILA);

  // --- Estado y prioridad (misma fila) ---
  LabelEn(FTabTarea, MARGEN, Y, 'Estado');
  FCbEstado := TcxComboBox.Create(Self);
  FCbEstado.Parent := FTabTarea;
  FCbEstado.SetBounds(MARGEN + ANCHO_ETQ, Y, ANCHO_ED, 22);
  FCbEstado.Properties.DropDownListStyle := lsFixedList;
  FCbEstado.Properties.Items.Add('Pendiente');
  FCbEstado.Properties.Items.Add('En curso');
  FCbEstado.Properties.Items.Add('Bloqueada');
  FCbEstado.Properties.Items.Add('Hecha');
  FCbEstado.Properties.Items.Add('Cancelada');

  LabelEn(FTabTarea, X2, Y, 'Prioridad', 70);
  FCbPrioridad := TcxComboBox.Create(Self);
  FCbPrioridad.Parent := FTabTarea;
  FCbPrioridad.SetBounds(X2 + 74, Y, ANCHO_ED, 22);
  FCbPrioridad.Properties.DropDownListStyle := lsFixedList;
  FCbPrioridad.Properties.Items.Add('Baja');
  FCbPrioridad.Properties.Items.Add('Normal');
  FCbPrioridad.Properties.Items.Add('Alta');
  FCbPrioridad.Properties.Items.Add('Critica');
  Inc(Y, ALTO_FILA);

  // ======================= Etiquetas ======================================
  Y := TituloBloque(FTabTarea, Y, 'Etiquetas');

  // --- Chips estilo Trello ---
  FLblEtiquetas := LabelEn(FTabTarea, MARGEN, Y, 'Etiquetas');
  FPnlTags := TPanel.Create(Self);
  FPnlTags.Parent := FTabTarea;
  FPnlTags.SetBounds(MARGEN + ANCHO_ETQ, Y - 2,
    ClientWidth - MARGEN * 2 - ANCHO_ETQ - 10, 30);
  FPnlTags.BevelOuter := bvNone;
  FPnlTags.Color := clWhite;
  FPnlTags.ParentBackground := False;
  FPnlTags.Anchors := [akLeft, akTop, akRight];
  // Y se avanza en ConstruirChips, cuando ya se sabe cuantas lineas ocupan:
  // aqui solo se reserva la posicion de partida.
  FYTrasTags := Y;

  // Las fechas, la restriccion y el esfuerzo ya NO estan aqui: viven en la
  // pestana TIEMPO (BuildTabTiempo). Los comentarios, en la suya (BuildTabNotas).
end;

function TfrmWbsTareaEdit.KpiEn(AParent: TWinControl; AX: Integer;
  const ARotulo: string): TLabel;
var
  Caja: TPanel;
  L: TLabel;
begin
  // Cada KPI es una CAJA alLeft dentro de la banda: se colocan una tras otra
  // solas, sin coordenadas absolutas que haya que cuadrar a mano. AX se ignora
  // (se conserva en la firma por si algun dia hace falta posicion fija).
  Caja := TPanel.Create(Self);
  Caja.Parent := AParent;
  Caja.Align := alLeft;
  Caja.Width := 165;
  Caja.BevelOuter := bvNone;
  Caja.ParentBackground := False;
  Caja.Color := $00F7F7F7;
  Caja.AlignWithMargins := True;
  Caja.Margins.SetBounds(MARGEN, 8, 0, 8);

  // Cifra grande arriba.
  Result := TLabel.Create(Self);
  Result.Parent := Caja;
  Result.Align := alTop;
  Result.AutoSize := False;
  Result.Height := 24;
  Result.Font.Style := [fsBold];
  Result.Font.Size := 12;
  Result.Font.Color := $00595959;
  Result.Caption := '-';

  // Rotulo debajo, pequeno y gris.
  L := TLabel.Create(Self);
  L.Parent := Caja;
  L.Align := alTop;
  L.AutoSize := False;
  L.Height := 16;
  L.Font.Size := 8;
  L.Font.Color := clGray;
  L.Caption := ARotulo;
end;

procedure TfrmWbsTareaEdit.DoOperariosChanged(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem);
begin
  if FCargando then Exit;
  RefrescarKpiOperarios;
end;

procedure TfrmWbsTareaEdit.RefrescarKpiOperarios;
var
  I, Marcados: Integer;
  V: Variant;
  Dedic, Horas, D, H: Double;
  T: TWbsTask;
begin
  if FTvOperarios = nil then Exit;

  Marcados := 0;
  Dedic := 0;
  Horas := 0;

  // Se lee del DataController, no de FData.Operarios: aqui interesa lo que hay
  // en pantalla AHORA, no lo ultimo guardado.
  for I := 0 to Min(FTvOperarios.DataController.RecordCount,
                    Length(FCatalogo)) - 1 do
  begin
    V := FTvOperarios.DataController.Values[I, FColSel.Index];
    if VarIsNull(V) or VarIsEmpty(V) or (not Boolean(V)) then Continue;

    Inc(Marcados);

    V := FTvOperarios.DataController.Values[I, FColDedic.Index];
    if VarIsNull(V) or VarIsEmpty(V) then D := 100 else D := V;
    if (D <= 0) or (D > 100) then D := 100;
    Dedic := Dedic + D;

    V := FTvOperarios.DataController.Values[I, FColHoras.Index];
    if VarIsNull(V) or VarIsEmpty(V) then H := 0 else H := V;
    Horas := Horas + Max(0, H);
  end;

  // Las unidades vigentes son las del GRID, no las ultimas guardadas: si no,
  // tras marcar a alguien el KPI y la linea de la ecuacion (que lee
  // FData.Unidades) dirian cosas distintas en la misma ficha.
  if Marcados > 0 then
    FData.Unidades := Dedic / 100
  else
    FData.Unidades := 1.0;

  if Marcados = 0 then
    FLblKpiOperarios.Caption := 'ninguno'
  else
    FLblKpiOperarios.Caption := IntToStr(Marcados);

  FLblKpiDedicacion.Caption := Format('%.0f %%', [Dedic]);
  // Mas del 100 % en UNA tarea no es sobreasignacion (dos personas a jornada
  // completa son 200 % y es perfectamente normal): solo se destaca cuando NO
  // llega a una persona entera, que suele ser un despiste al teclear.
  if (Marcados > 0) and (Dedic < 100) then
    FLblKpiDedicacion.Font.Color := $000090FF
  else
    FLblKpiDedicacion.Font.Color := $00595959;

  FLblKpiHoras.Caption := Format('%.1f h', [Horas]);

  // Trabajo que sale de la ecuacion con la asignacion actual. Es el puente con
  // la pestana Tiempo: deja ver de inmediato si marcar a alguien mas cambia el
  // esfuerzo o la duracion, segun el tipo de calculo.
  T := Default(TWbsTask);
  T.Kind := FData.Kind;
  T.TipoTarea := TWbsTipoTarea(Max(0, FCbTipoTarea.ItemIndex));
  T.DuracionMin := DuracionEditadaMin;
  T.TrabajoMin := FEdTrabajo.Value * 60;
  if Marcados > 0 then T.Unidades := Dedic / 100 else T.Unidades := 1.0;
  T := RecalcularTriada(T, wceUnidades);
  FLblKpiTrabajo.Caption := Format('%.1f h', [T.TrabajoMin / 60]);

  // FData.Unidades acaba de cambiar, y la linea de la ecuacion (pestana
  // Tiempo) la muestra: repintarla para que las dos pestanas digan lo mismo.
  if FLblUnidades <> nil then
    RefrescarEcuacion;
end;

function TfrmWbsTareaEdit.TituloBloque(AParent: TWinControl; AY: Integer;
  const ACaption: string; APrimero: Boolean): Integer;
var
  L: TLabel;
  Linea: TPanel;
begin
  // El primer bloque de una pestana no necesita aire por encima: ya lo da el
  // margen superior.
  if not APrimero then Inc(AY, SEP_BLOQUE);

  L := TLabel.Create(Self);
  L.Parent := AParent;
  L.SetBounds(MARGEN, AY, 300, 18);
  L.Caption := ACaption;
  L.Font.Style := [fsBold];
  L.Font.Color := $00707070;

  // Filete bajo el titulo: separa los bloques sin gastar una fila entera, que
  // es lo que hacia falta para que la ficha dejara de leerse como un muro.
  Linea := TPanel.Create(Self);
  Linea.Parent := AParent;
  Linea.SetBounds(MARGEN, AY + 20, ClientWidth - MARGEN * 3, 1);
  Linea.BevelOuter := bvNone;
  Linea.Color := $00E0E0E0;
  Linea.ParentBackground := False;
  Linea.Anchors := [akLeft, akTop, akRight];

  Result := AY + 30;
end;

procedure TfrmWbsTareaEdit.BuildTabTiempo;
var
  Y, X2, XNota: Integer;
begin
  Y := MARGEN;
  X2 := MARGEN + ANCHO_ETQ + ANCHO_ED + 30;
  // Columna donde arrancan las notas grises de la derecha. Unica para todas,
  // asi quedan alineadas en vertical en vez de cada una a su aire.
  XNota := MARGEN + ANCHO_ETQ + 104;

  // ======================= Fechas =========================================
  Y := TituloBloque(FTabTiempo, Y, 'Fechas', True);

  LabelEn(FTabTiempo, MARGEN, Y, 'Inicio');
  FEdInicio := TcxDateEdit.Create(Self);
  FEdInicio.Parent := FTabTiempo;
  FEdInicio.SetBounds(MARGEN + ANCHO_ETQ, Y, ANCHO_ED, 22);

  LabelEn(FTabTiempo, X2, Y, 'Fin', 70);
  FEdFin := TcxDateEdit.Create(Self);
  FEdFin.Parent := FTabTiempo;
  FEdFin.SetBounds(X2 + 74, Y, ANCHO_ED, 22);
  // El fin lo calcula el motor a partir de inicio + duracion: mostrarlo
  // editable invitaria a introducir una incoherencia.
  FEdFin.Properties.ReadOnly := True;
  FEdFin.Style.Color := $00F0F0F0;
  Inc(Y, ALTO_FILA);

  // --- Restriccion de fecha (juego completo de MS Project, V082) ------------
  // Antes, teclear el inicio convertia la tarea en "fecha fija" sin decirlo.
  // Ahora se elige de forma explicita: una restriccion es una decision de
  // planificacion, no un efecto colateral de rellenar un campo.
  LabelEn(FTabTiempo, MARGEN, Y, 'Restricci'#243'n');
  FCbRestriccion := TcxComboBox.Create(Self);
  FCbRestriccion.Parent := FTabTiempo;
  FCbRestriccion.SetBounds(MARGEN + ANCHO_ETQ, Y, ANCHO_ED + 60, 22);
  FCbRestriccion.Properties.DropDownListStyle := lsFixedList;
  // El orden DEBE coincidir con TWbsConstraintKind (0..7).
  FCbRestriccion.Properties.Items.Add('Lo antes posible');
  FCbRestriccion.Properties.Items.Add('No comenzar antes del');
  FCbRestriccion.Properties.Items.Add('Debe comenzar el');
  FCbRestriccion.Properties.Items.Add('Lo m'#225's tarde posible');
  FCbRestriccion.Properties.Items.Add('No comenzar despu'#233's del');
  FCbRestriccion.Properties.Items.Add('No finalizar antes del');
  FCbRestriccion.Properties.Items.Add('No finalizar despu'#233's del');
  FCbRestriccion.Properties.Items.Add('Debe finalizar el');
  FCbRestriccion.Properties.OnChange := DoRestriccionChange;

  FEdFechaRestr := TcxDateEdit.Create(Self);
  FEdFechaRestr.Parent := FTabTiempo;
  FEdFechaRestr.SetBounds(MARGEN + ANCHO_ETQ + ANCHO_ED + 70, Y, ANCHO_ED, 22);
  Inc(Y, ALTO_FILA - 8);

  FLblAvisoRestr := LabelEn(FTabTiempo, MARGEN + ANCHO_ETQ, Y, '', 460);
  FLblAvisoRestr.Font.Color := clGray;
  Inc(Y, 20);

  // ======================= Esfuerzo =======================================
  Y := TituloBloque(FTabTiempo, Y, 'Esfuerzo');

  // --- Duracion en dias / horas / minutos ---
  LabelEn(FTabTiempo, MARGEN, Y, 'Duraci'#243'n');
  FEdDias := TcxSpinEdit.Create(Self);
  FEdDias.Parent := FTabTiempo;
  FEdDias.SetBounds(MARGEN + ANCHO_ETQ, Y, 62, 22);
  FEdDias.Properties.MinValue := 0;
  FEdDias.Properties.MaxValue := 9999;
  FEdDias.Properties.OnChange := DoDuracionChange;
  LabelEn(FTabTiempo, MARGEN + ANCHO_ETQ + 66, Y, 'd', 16).Font.Color := clGray;

  FEdHoras := TcxSpinEdit.Create(Self);
  FEdHoras.Parent := FTabTiempo;
  FEdHoras.SetBounds(MARGEN + ANCHO_ETQ + 84, Y, 56, 22);
  FEdHoras.Properties.MinValue := 0;
  FEdHoras.Properties.MaxValue := 23;
  FEdHoras.Properties.OnChange := DoDuracionChange;
  LabelEn(FTabTiempo, MARGEN + ANCHO_ETQ + 144, Y, 'h', 16).Font.Color := clGray;

  FEdMinutos := TcxSpinEdit.Create(Self);
  FEdMinutos.Parent := FTabTiempo;
  FEdMinutos.SetBounds(MARGEN + ANCHO_ETQ + 162, Y, 56, 22);
  FEdMinutos.Properties.MinValue := 0;
  FEdMinutos.Properties.MaxValue := 59;
  FEdMinutos.Properties.OnChange := DoDuracionChange;
  LabelEn(FTabTiempo, MARGEN + ANCHO_ETQ + 222, Y, 'min', 30).Font.Color := clGray;
  Inc(Y, ALTO_FILA);

  // --- Triada: Trabajo = Duracion x Unidades (V082) ---
  LabelEn(FTabTiempo, MARGEN, Y, 'Trabajo');
  FEdTrabajo := TcxSpinEdit.Create(Self);
  FEdTrabajo.Parent := FTabTiempo;
  FEdTrabajo.SetBounds(MARGEN + ANCHO_ETQ, Y, 90, 22);
  FEdTrabajo.Properties.MinValue := 0;
  FEdTrabajo.Properties.MaxValue := 99999;
  FEdTrabajo.Properties.ValueType := vtFloat;
  FEdTrabajo.Properties.OnChange := DoTrabajoChange;
  LabelEn(FTabTiempo, XNota, Y, 'horas', 40).Font.Color := clGray;

  FLblUnidades := LabelEn(FTabTiempo, XNota + 46, Y, '', 260);
  FLblUnidades.Font.Color := clGray;
  Inc(Y, ALTO_FILA);

  // Que magnitud queda fija al recalcular las otras dos.
  LabelEn(FTabTiempo, MARGEN, Y, 'Tipo de c'#225'lculo');
  FCbTipoTarea := TcxComboBox.Create(Self);
  FCbTipoTarea.Parent := FTabTiempo;
  FCbTipoTarea.SetBounds(MARGEN + ANCHO_ETQ, Y, ANCHO_ED, 22);
  FCbTipoTarea.Properties.DropDownListStyle := lsFixedList;
  // El orden DEBE coincidir con TWbsTipoTarea (0..2).
  FCbTipoTarea.Properties.Items.Add('Duraci'#243'n fija');
  FCbTipoTarea.Properties.Items.Add('Trabajo fijo');
  FCbTipoTarea.Properties.Items.Add('Unidades fijas');
  FCbTipoTarea.Properties.OnChange := DoTipoTareaChange;
  Inc(Y, ALTO_FILA - 8);

  // Linea viva que explica que pasara al tocar cada campo. Sin ella, que la
  // duracion cambie sola al teclear el trabajo parece un error del programa.
  //
  // NO se crea con LabelEn: ese helper fija un alto de 20 px pensado para una
  // sola linea, y con WordWrap el texto se partia en dos y quedaba recortado
  // (se veian dos restos de linea en vez del rotulo). Aqui hace falta control
  // explicito del alto.
  FLblEcuacion := TLabel.Create(Self);
  FLblEcuacion.Parent := FTabTiempo;
  FLblEcuacion.AutoSize := False;
  FLblEcuacion.WordWrap := True;
  FLblEcuacion.SetBounds(MARGEN + ANCHO_ETQ, Y + 4,
    ClientWidth - MARGEN - ANCHO_ETQ - MARGEN * 2, 34);
  FLblEcuacion.Font.Color := clGray;
  FLblEcuacion.Anchors := [akLeft, akTop, akRight];
  Inc(Y, 42);

  // ======================= Dedicacion real ================================
  Y := TituloBloque(FTabTiempo, Y, 'Dedicaci'#243'n real');

  // --- Esfuerzo estimado inicial (la estimacion del responsable) ---
  // Se conserva junto al trabajo del plan a proposito: uno es lo que se creia
  // que costaria y el otro lo que el plan dice que cuesta. Que diverjan es
  // informacion, no un error.
  LabelEn(FTabTiempo, MARGEN, Y, 'Estimaci'#243'n inicial');
  FEdEsfuerzo := TcxSpinEdit.Create(Self);
  FEdEsfuerzo.Parent := FTabTiempo;
  FEdEsfuerzo.SetBounds(MARGEN + ANCHO_ETQ, Y, 90, 22);
  FEdEsfuerzo.Properties.MinValue := 0;
  FEdEsfuerzo.Properties.MaxValue := 99999;
  FEdEsfuerzo.Properties.ValueType := vtFloat;
  LabelEn(FTabTiempo, XNota, Y,
    'horas previstas al abrir la tarea', ANCHO_NOTA).Font.Color := clGray;
  Inc(Y, ALTO_FILA);

  // --- Tiempo invertido (V079) ---
  LabelEn(FTabTiempo, MARGEN, Y, 'Tiempo invertido');
  FEdInvertido := TcxSpinEdit.Create(Self);
  FEdInvertido.Parent := FTabTiempo;
  FEdInvertido.SetBounds(MARGEN + ANCHO_ETQ, Y, 90, 22);
  FEdInvertido.Properties.MinValue := 0;
  FEdInvertido.Properties.MaxValue := 99999;
  FEdInvertido.Properties.ValueType := vtFloat;
  FEdInvertido.Properties.OnChange := DoInvertidoChange;
  LabelEn(FTabTiempo, XNota, Y,
    'horas dedicadas hasta hoy', ANCHO_NOTA).Font.Color := clGray;
  Inc(Y, ALTO_FILA - 8);

  FLblAviso := TLabel.Create(Self);
  FLblAviso.Parent := FTabTiempo;
  FLblAviso.SetBounds(MARGEN + ANCHO_ETQ, Y, 440, 18);
  FLblAviso.Font.Color := $000090FF;
  FLblAviso.Visible := False;
end;

procedure TfrmWbsTareaEdit.BuildTabOperarios;
var
  PnlCab: TPanel;
begin
  // Toda la pestana va por ALIGN, no por SetBounds+Anchors. Mezclar los dos no
  // funciona: al construir el form la pestana aun no tiene su tamano final, asi
  // que el alto calculado a mano salia mal y la banda de KPIs quedaba aplastada
  // a unos pocos pixeles. Con Align el reparto lo hace la VCL cuando el tamano
  // ya es el bueno. ORDEN OBLIGATORIO: primero los alTop/alBottom, el alClient
  // el ULTIMO (se queda con lo que sobra).
  PnlCab := TPanel.Create(Self);
  PnlCab.Parent := FTabOperarios;
  PnlCab.Align := alTop;
  PnlCab.Height := 34;
  PnlCab.BevelOuter := bvNone;
  PnlCab.Color := clWhite;
  PnlCab.ParentBackground := False;
  LabelEn(PnlCab, MARGEN, 4,
    'Marca las personas asignadas y ajusta su dedicaci'#243'n:', 420);

  // Barra de KPIs al PIE: cuantos van marcados, cuanta dedicacion suman y que
  // trabajo sale de ahi. Sin esto hay que contar los checks a mano en una lista
  // de cientos de operarios para saber si la asignacion cuadra con el esfuerzo
  // de la pestana Tiempo.
  FPnlKpiOper := TPanel.Create(Self);
  FPnlKpiOper.Parent := FTabOperarios;
  FPnlKpiOper.Align := alBottom;
  FPnlKpiOper.Height := 62;
  FPnlKpiOper.BevelOuter := bvNone;
  FPnlKpiOper.Color := $00F7F7F7;
  FPnlKpiOper.ParentBackground := False;

  // Cada tarjeta es un panel alLeft de ancho fijo: asi se reparten solas y no
  // dependen de coordenadas absolutas que se descuadran al redimensionar.
  FLblKpiOperarios  := KpiEn(FPnlKpiOper, 0, 'Asignados');
  FLblKpiDedicacion := KpiEn(FPnlKpiOper, 0, 'Dedicaci'#243'n total');
  FLblKpiHoras      := KpiEn(FPnlKpiOper, 0, 'Horas imputadas');
  FLblKpiTrabajo    := KpiEn(FPnlKpiOper, 0, 'Trabajo del plan');

  FGridOperarios := TcxGrid.Create(Self);
  FGridOperarios.Parent := FTabOperarios;
  FGridOperarios.Align := alClient;   // el ultimo: ocupa lo que queda
  FGridOperarios.AlignWithMargins := True;
  FGridOperarios.Margins.SetBounds(MARGEN, 0, MARGEN, MARGEN);

  FLvlOperarios := FGridOperarios.Levels.Add;
  FTvOperarios := FGridOperarios.CreateView(TcxGridTableView)
    as TcxGridTableView;
  FLvlOperarios.GridView := FTvOperarios;

  FTvOperarios.OptionsView.GroupByBox := False;
  FTvOperarios.OptionsView.Indicator := False;
  FTvOperarios.OptionsData.Deleting := False;
  FTvOperarios.OptionsData.Inserting := False;
  // IMPRESCINDIBLE: sin esto el grid es de solo lectura y no se puede marcar
  // ningun operario (era justo lo que fallaba). Y CellSelect debe estar a True
  // o no se puede entrar a editar una celda concreta.
  FTvOperarios.OptionsData.Editing := True;
  FTvOperarios.OptionsSelection.CellSelect := True;
  // Un solo clic sobre el check ya lo cambia, sin tener que entrar en edicion.
  FTvOperarios.OptionsBehavior.ImmediateEditor := True;
  FTvOperarios.OptionsBehavior.FocusCellOnCycle := True;
  FTvOperarios.DataController.RecordCount := 0;
  // Marcar a alguien o cambiar su dedicacion mueve los KPIs del pie.
  FTvOperarios.OnEditValueChanged := DoOperariosChanged;

  // Columna de marcado.
  FColSel := FTvOperarios.CreateColumn;
  FColSel.Caption := '';
  FColSel.Width := 34;
  FColSel.PropertiesClass := TcxCheckBoxProperties;
  FColSel.DataBinding.ValueTypeClass := TcxBooleanValueType;
  FColSel.Options.Editing := True;
  // Que el check no muestre estado "gris" (null): solo marcado o sin marcar.
  TcxCheckBoxProperties(FColSel.Properties).AllowGrayed := False;
  TcxCheckBoxProperties(FColSel.Properties).NullStyle := nssUnchecked;

  FColNombre := FTvOperarios.CreateColumn;
  FColNombre.Caption := 'Operario';
  FColNombre.Width := 220;
  FColNombre.Options.Editing := False;
  FColNombre.DataBinding.ValueTypeClass := TcxStringValueType;

  FColDedic := FTvOperarios.CreateColumn;
  FColDedic.Caption := '% dedicacion';
  FColDedic.Width := 95;
  FColDedic.PropertiesClass := TcxSpinEditProperties;
  TcxSpinEditProperties(FColDedic.Properties).MinValue := 1;
  TcxSpinEditProperties(FColDedic.Properties).MaxValue := 100;
  FColDedic.DataBinding.ValueTypeClass := TcxFloatValueType;
  FColDedic.Options.Editing := True;

  FColHoras := FTvOperarios.CreateColumn;
  FColHoras.Caption := 'Horas imputadas';
  FColHoras.Width := 110;
  FColHoras.PropertiesClass := TcxSpinEditProperties;
  TcxSpinEditProperties(FColHoras.Properties).MinValue := 0;
  TcxSpinEditProperties(FColHoras.Properties).MaxValue := 99999;
  TcxSpinEditProperties(FColHoras.Properties).ValueType := vtFloat;
  FColHoras.DataBinding.ValueTypeClass := TcxFloatValueType;
  FColHoras.Options.Editing := True;
end;

procedure TfrmWbsTareaEdit.CargarDatos;
var
  I, J: Integer;
  Dias, Resto: Integer;
begin
  FCargando := True;
  try
    FLblTarea.Caption := FData.Caption;

    FCbTipo.ItemIndex := Ord(FData.Kind);
    FCbEstado.ItemIndex := Ord(FData.Detail.Estado);
    FCbPrioridad.ItemIndex := Ord(FData.Detail.Prioridad);
    ConstruirChips;

    if FData.FechaInicio > 0 then FEdInicio.Date := FData.FechaInicio;
    if FData.FechaFin > 0 then FEdFin.Date := FData.FechaFin;

    // Duracion: minutos -> dias / horas / minutos.
    Dias := Trunc(FData.DuracionMin / FJornadaMin);
    Resto := Round(FData.DuracionMin - Dias * FJornadaMin);
    FEdDias.Value := Dias;
    FEdHoras.Value := Resto div 60;
    FEdMinutos.Value := Resto mod 60;

    FEdEsfuerzo.Value := FData.Detail.HorasEstimadas / 60;
    FEdInvertido.Value := FData.MinutosInvertidos / 60;
    FMemoNotas.Text := FData.Detail.Notas;

    // Triada de esfuerzo (V082).
    if FData.Unidades <= 0 then FData.Unidades := 1.0;
    FEdTrabajo.Value := FData.TrabajoMin / 60;
    FCbTipoTarea.ItemIndex := Ord(FData.TipoTarea);

    // Restriccion de fecha.
    if (FData.ConstraintKind >= 0) and (FData.ConstraintKind <= 7) then
      FCbRestriccion.ItemIndex := FData.ConstraintKind
    else
      FCbRestriccion.ItemIndex := 0;
    if FData.ConstraintDate > 0 then
      FEdFechaRestr.Date := FData.ConstraintDate
    else
      FEdFechaRestr.Clear;

    // Habilitar/bloquear campos segun el tipo (hito sin duracion, resumen
    // calculado a partir de sus hijos).
    AplicarTipo;
    AplicarRestriccion;
    RefrescarEcuacion;

    // --- Catalogo de operarios, marcando los ya asignados ---
    FTvOperarios.BeginUpdate;
    try
      FTvOperarios.DataController.RecordCount := Length(FCatalogo);
      for I := 0 to High(FCatalogo) do
      begin
        FTvOperarios.DataController.Values[I, FColSel.Index] := False;
        FTvOperarios.DataController.Values[I, FColNombre.Index] :=
          FCatalogo[I].Nombre;
        FTvOperarios.DataController.Values[I, FColDedic.Index] := 100;
        FTvOperarios.DataController.Values[I, FColHoras.Index] := 0;

        for J := 0 to High(FData.Operarios) do
          if FData.Operarios[J].OperatorId = FCatalogo[I].OperatorId then
          begin
            FTvOperarios.DataController.Values[I, FColSel.Index] := True;
            FTvOperarios.DataController.Values[I, FColDedic.Index] :=
              FData.Operarios[J].Dedicacion;
            FTvOperarios.DataController.Values[I, FColHoras.Index] :=
              FData.Operarios[J].MinutosImputados / 60;
            Break;
          end;
      end;
    finally
      FTvOperarios.EndUpdate;
    end;

    RefrescarAvance;
  finally
    FCargando := False;
  end;

  // Fuera del FCargando: los KPIs se calculan sobre lo que ya esta volcado en
  // el grid, y no deben quedar bloqueados por el flag.
  RefrescarKpiOperarios;
end;

function TfrmWbsTareaEdit.DuracionEditadaMin: Double;
begin
  Result := FEdDias.Value * FJornadaMin + FEdHoras.Value * 60 + FEdMinutos.Value;
end;

procedure TfrmWbsTareaEdit.AplicarTriada(ACampo: TWbsCampoEditado);
var
  T: TWbsTask;
begin
  // Se delega en RecalcularTriada (uWbsTypes): la ecuacion vive en UN sitio y
  // el dialogo no la reimplementa. Aqui solo se traduce a los controles.
  if FCargando then Exit;
  if FData.EsHito then Exit;   // un hito no dura ni cuesta

  T := Default(TWbsTask);
  T.Kind := FData.Kind;
  T.TipoTarea := TWbsTipoTarea(Max(0, FCbTipoTarea.ItemIndex));
  T.DuracionMin := DuracionEditadaMin;
  T.TrabajoMin := FEdTrabajo.Value * 60;
  T.Unidades := FData.Unidades;

  T := RecalcularTriada(T, ACampo);

  FCargando := True;   // evitar que escribir en un control dispare al otro
  try
    case ACampo of
      wceDuracion:
        FEdTrabajo.Value := T.TrabajoMin / 60;
      wceTrabajo:
        if T.TipoTarea <> wttDuracionFija then
        begin
          // Con duracion fija, teclear el trabajo cambia las UNIDADES, no la
          // duracion: los editores de dias/horas no se tocan.
          FEdDias.Value := Trunc(T.DuracionMin / FJornadaMin);
          FEdHoras.Value := Round(T.DuracionMin -
            FEdDias.Value * FJornadaMin) div 60;
          FEdMinutos.Value := Round(T.DuracionMin -
            FEdDias.Value * FJornadaMin) mod 60;
        end;
      wceUnidades:
        begin
          FEdTrabajo.Value := T.TrabajoMin / 60;
          FEdDias.Value := Trunc(T.DuracionMin / FJornadaMin);
          FEdHoras.Value := Round(T.DuracionMin -
            FEdDias.Value * FJornadaMin) div 60;
          FEdMinutos.Value := Round(T.DuracionMin -
            FEdDias.Value * FJornadaMin) mod 60;
        end;
    end;
    FData.Unidades := T.Unidades;
  finally
    FCargando := False;
  end;

  RefrescarEcuacion;
  // Todo cambio de la triada pasa por aqui, asi que es el sitio para mantener
  // al dia el KPI "Trabajo del plan" del pie de la pestana Operarios.
  RefrescarKpiOperarios;
end;

procedure TfrmWbsTareaEdit.RefrescarEcuacion;
var
  U: Double;
  Explicacion: string;
begin
  U := FData.Unidades;
  if U <= 0 then U := 1.0;

  if Length(FData.Operarios) = 0 then
    FLblUnidades.Caption := Format('%.0f %% (sin operarios asignados)', [U * 100])
  else
    FLblUnidades.Caption := Format('%.0f %% entre %d operario(s)',
      [U * 100, Length(FData.Operarios)]);

  // Decir de antemano que pasara al tocar cada campo: si no, ver como cambia
  // solo un valor que no has tocado parece un fallo del programa.
  case TWbsTipoTarea(Max(0, FCbTipoTarea.ItemIndex)) of
    wttTrabajoFijo:
      Explicacion := 'El trabajo manda: a'#241'adir operarios ACORTA la tarea.';
    wttUnidadesFijas:
      Explicacion := 'El equipo manda: m'#225's trabajo alarga la duraci'#243'n.';
  else
    Explicacion := 'La duraci'#243'n manda: a'#241'adir operarios sube el trabajo total.';
  end;

  FLblEcuacion.Caption := Format('Trabajo = Duraci'#243'n x Unidades.  %s',
    [Explicacion]);
end;

procedure TfrmWbsTareaEdit.DoTrabajoChange(Sender: TObject);
begin
  if FCargando then Exit;
  AplicarTriada(wceTrabajo);
  RefrescarAvance;
end;

procedure TfrmWbsTareaEdit.DoTipoTareaChange(Sender: TObject);
begin
  if FCargando then Exit;
  // Cambiar el tipo no recalcula nada por si solo: solo cambia QUE se
  // recalculara la proxima vez. Se refresca la explicacion y ya.
  RefrescarEcuacion;
  // El KPI "Trabajo del plan" depende del tipo de calculo.
  RefrescarKpiOperarios;
end;

procedure TfrmWbsTareaEdit.DoRestriccionChange(Sender: TObject);
begin
  if FCargando then Exit;
  AplicarRestriccion;
end;

procedure TfrmWbsTareaEdit.AplicarRestriccion;
var
  K: TWbsConstraintKind;
  NecesitaFecha: Boolean;
begin
  K := TWbsConstraintKind(Max(0, FCbRestriccion.ItemIndex));

  // Las dos FLEXIBLES (ASAP y ALAP) no atan a ninguna fecha: pedirla seria
  // pedir un dato que el motor va a ignorar.
  NecesitaFecha := not (K in [wckASAP, wckALAP]);
  FEdFechaRestr.Enabled := NecesitaFecha;
  if not NecesitaFecha then
    FEdFechaRestr.Clear;

  case K of
    wckASAP:
      FLblAvisoRestr.Caption :=
        'La tarea se coloca lo antes que permitan sus predecesoras.';
    wckALAP:
      FLblAvisoRestr.Caption :=
        'La tarea se retrasa al m'#225'ximo sin retrasar el proyecto ' +
        '(quedar'#225' en el camino cr'#237'tico).';
    wckMSO, wckMFO:
      FLblAvisoRestr.Caption :=
        'Restricci'#243'n R'#205'GIDA: el motor NO mover'#225' la tarea aunque sus ' +
        'predecesoras se retrasen.';
  else
    FLblAvisoRestr.Caption :=
      'Restricci'#243'n con fecha l'#237'mite: el motor la respeta al recalcular.';
  end;
end;

procedure TfrmWbsTareaEdit.RefrescarAvance;
var
  Dur, Inv, Av: Double;
begin
  Dur := DuracionEditadaMin;
  Inv := FEdInvertido.Value * 60;
  Av := AvanceTarea(Inv, Dur);

  FLblAvanceValor.Caption := Format('%.0f %%', [Av * 100]);

  // El rotulo dice de DONDE sale la cifra: "56 %" a secas no se entiende, y
  // con las horas delante se lee sin tener que ir a la pestana Tiempo.
  if Dur > 0 then
    FLblAvanceRotulo.Caption := Format('avance  %.0f/%.0f h',
      [Inv / 60, Dur / 60])
  else
    FLblAvanceRotulo.Caption := 'avance';

  if (not FData.EsHito) and (Av > 1.0) then
  begin
    FLblAvanceValor.Font.Color := $000090FF;   // ambar
    FLblAviso.Caption := Format('Desviacion: %.1f h por encima de lo estimado.',
      [(Inv - Dur) / 60]);
    FLblAviso.Visible := True;
  end
  else
  begin
    FLblAvanceValor.Font.Color := $00595959;
    FLblAviso.Visible := False;
  end;
end;

procedure TfrmWbsTareaEdit.PintarChip(AChip: TPanel; const ATag: TWbsTag);
var
  Lbl: TLabel;
begin
  Lbl := TLabel(AChip.Controls[0]);
  if ATag.Asignada then
  begin
    // Asignada: chip solido con el color de la etiqueta.
    AChip.Color := ATag.Color;
    Lbl.Font.Color := clWhite;
    Lbl.Font.Style := [fsBold];
  end
  else
  begin
    // Sin asignar: apagado, para que se vea que esta disponible pero no puesto.
    AChip.Color := $00F0F0F0;
    Lbl.Font.Color := $00808080;
    Lbl.Font.Style := [];
  end;
end;

procedure TfrmWbsTareaEdit.ConstruirChips;
var
  I, X, Y, Ancho, AnchoDisp: Integer;
  Chip: TPanel;
  Lbl: TLabel;
begin
  for I := FChips.Count - 1 downto 0 do
    FChips[I].Free;
  FChips.Clear;

  // Los chips FLUYEN en varias lineas: con una sola fila el ultimo quedaba
  // cortado y el boton "+" ni siquiera cabia.
  AnchoDisp := FPnlTags.Width;
  if AnchoDisp < 100 then AnchoDisp := 300;   // aun sin tamano real
  X := 0;
  Y := 2;

  for I := 0 to High(FTags) do
  begin
    Chip := TPanel.Create(Self);
    Chip.Parent := FPnlTags;
    Chip.BevelOuter := bvNone;
    Chip.ParentBackground := False;
    Chip.Tag := I;                 // indice en FTags
    Chip.Cursor := crHandPoint;
    Chip.OnClick := DoChipClick;

    // El ancho se mide con el Canvas del FORM: el de un TLabel recien creado
    // aun no tiene la fuente definitiva y devolvia 0, asi que los chips salian
    // de ancho cero (invisibles).
    Canvas.Font.Assign(Font);
    Canvas.Font.Size := 8;
    Ancho := Canvas.TextWidth(FTags[I].Nombre) + 22;

    // Salto de linea si no cabe (dejando hueco para el boton "+").
    if (X > 0) and (X + Ancho > AnchoDisp - 34) then
    begin
      X := 0;
      Inc(Y, 26);
    end;

    Chip.SetBounds(X, Y, Ancho, 22);
    Inc(X, Ancho + 6);

    Lbl := TLabel.Create(Self);
    Lbl.Parent := Chip;
    Lbl.Caption := FTags[I].Nombre;
    Lbl.Align := alClient;
    Lbl.Alignment := taCenter;
    Lbl.Layout := tlCenter;
    Lbl.Font.Size := 8;
    Lbl.Transparent := True;
    // El clic sobre la etiqueta debe alternar el chip igual que sobre el panel.
    Lbl.OnClick := DoChipClick;
    Lbl.Tag := I;
    Lbl.Cursor := crHandPoint;

    PintarChip(Chip, FTags[I]);
    FChips.Add(Chip);
  end;

  // Chip "+": crear una etiqueta nueva sin salir de la ficha.
  if (X > 0) and (X + 30 > AnchoDisp) then
  begin
    X := 0;
    Inc(Y, 26);
  end;

  Chip := TPanel.Create(Self);
  Chip.Parent := FPnlTags;
  Chip.BevelOuter := bvNone;
  Chip.ParentBackground := False;
  Chip.Color := $00F7F7F7;
  Chip.Cursor := crHandPoint;
  Chip.SetBounds(X, Y, 28, 22);
  Chip.OnClick := DoNuevoTag;
  Chip.Hint := 'Crear una etiqueta nueva';
  Chip.ShowHint := True;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Chip;
  Lbl.Caption := '+';
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Font.Size := 11;
  Lbl.Font.Color := $00808080;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := DoNuevoTag;

  FChips.Add(Chip);

  // Ajustar el alto del panel a las lineas que han salido, para que no se
  // corte la ultima fila de chips.
  FPnlTags.Height := Y + 26;

  // Y empujar hacia abajo todo lo que va DEBAJO de las etiquetas: si no, al
  // ocupar los chips mas de una linea se solapaban con el campo Inicio.
  ReubicarTrasTags;
end;

procedure TfrmWbsTareaEdit.ReubicarTrasTags;
begin
  // Ya no hay nada que reubicar: las etiquetas son el ULTIMO bloque de la
  // pestana Tarea (las fechas y el esfuerzo se fueron a la pestana Tiempo), asi
  // que pueden crecer a varias lineas sin empujar a nadie. Se conserva el
  // metodo porque ConstruirChips lo llama tras recalcular las filas de chips;
  // si algun dia vuelve a haber controles debajo, este es el sitio.
end;

procedure TfrmWbsTareaEdit.DoNuevoTag(Sender: TObject);
var
  Nombre: string;
  T: TWbsTag;
  Dlg: TColorDialog;
begin
  Nombre := '';
  if not InputQuery('Nueva etiqueta', 'Nombre de la etiqueta:', Nombre) then Exit;
  Nombre := Trim(Nombre);
  if Nombre = '' then Exit;

  // Color: el selector estandar de Windows, con un color de partida agradable.
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := COLORES_TAG[Length(FTags) mod Length(COLORES_TAG)];
    if not Dlg.Execute then Exit;

    T := Default(TWbsTag);
    T.TagId := 0;                    // 0 = alta; el repo devuelve el id real
    T.Nombre := Nombre;
    T.Color := Dlg.Color;
    T.Orden := Length(FTags) + 1;
    T.Asignada := True;              // recien creada, se asigna a esta tarea
  finally
    Dlg.Free;
  end;

  // Alta inmediata en el catalogo: si se dejara para el Aceptar, una etiqueta
  // creada y luego cancelada se perderia sin que el usuario lo entienda.
  if Assigned(FOnNuevoTag) then
    T.TagId := FOnNuevoTag(T);
  if T.TagId <= 0 then Exit;

  SetLength(FTags, Length(FTags) + 1);
  FTags[High(FTags)] := T;
  ConstruirChips;
end;

procedure TfrmWbsTareaEdit.DoChipClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := TComponent(Sender).Tag;
  if (Idx < 0) or (Idx > High(FTags)) then Exit;

  FTags[Idx].Asignada := not FTags[Idx].Asignada;
  PintarChip(FChips[Idx], FTags[Idx]);
end;

procedure TfrmWbsTareaEdit.DoTipoChange(Sender: TObject);
begin
  if FCargando then Exit;
  AplicarTipo;
end;

procedure TfrmWbsTareaEdit.AplicarTipo;
var
  Kind: TWbsTaskKind;
  EsHito, EsResumen: Boolean;
begin
  Kind := TWbsTaskKind(Max(0, FCbTipo.ItemIndex));
  EsHito := Kind = wtkHito;
  EsResumen := Kind = wtkResumen;

  // Un hito no dura ni consume horas: se alcanza o no. Un resumen tampoco se
  // edita: su duracion y su avance los AGREGA el motor a partir de sus hijos.
  FEdDias.Enabled := not (EsHito or EsResumen);
  FEdHoras.Enabled := FEdDias.Enabled;
  FEdMinutos.Enabled := FEdDias.Enabled;
  FEdEsfuerzo.Enabled := FEdDias.Enabled;
  FEdInvertido.Enabled := FEdDias.Enabled;
  // La triada tampoco aplica: un hito no cuesta trabajo y el de un resumen es
  // la suma del de sus hijos (V082).
  FEdTrabajo.Enabled := FEdDias.Enabled;
  FCbTipoTarea.Enabled := FEdDias.Enabled;
  FLblEcuacion.Visible := FEdDias.Enabled;
  FLblUnidades.Visible := FEdDias.Enabled;

  if EsHito then
  begin
    FLblAvisoTipo.Caption := 'Un hito no tiene duracion.';
    FEdDias.Value := 0;
    FEdHoras.Value := 0;
    FEdMinutos.Value := 0;
    FEdTrabajo.Value := 0;
  end
  else if EsResumen then
    FLblAvisoTipo.Caption := 'La duracion y el avance salen de sus hijos.'
  else
    FLblAvisoTipo.Caption := '';

  RefrescarAvance;
end;

procedure TfrmWbsTareaEdit.DoDuracionChange(Sender: TObject);
begin
  if FCargando then Exit;
  // Tocar la duracion mueve la ecuacion de esfuerzo (V082).
  AplicarTriada(wceDuracion);
  RefrescarAvance;
end;

procedure TfrmWbsTareaEdit.DoInvertidoChange(Sender: TObject);
begin
  if FCargando then Exit;
  RefrescarAvance;
end;

procedure TfrmWbsTareaEdit.VolcarDatos;
var
  I: Integer;
  D, H: Double;
  V: Variant;
  Ops: TList<TWbsTaskOperario>;
  O: TWbsTaskOperario;
  T: TWbsTask;
begin
  FData.Kind := TWbsTaskKind(Max(0, FCbTipo.ItemIndex));
  FData.EsHito := FData.Kind = wtkHito;
  FData.Detail.Estado := TWbsTaskEstado(Max(0, FCbEstado.ItemIndex));
  FData.Detail.Prioridad := TWbsTaskPrioridad(Max(0, FCbPrioridad.ItemIndex));
  FData.Tags := FTags;   // los chips ya han ido marcando Asignada
  FData.Detail.Notas := FMemoNotas.Text;
  FData.Detail.HorasEstimadas := FEdEsfuerzo.Value * 60;

  // Triada de esfuerzo (V082).
  FData.TipoTarea := TWbsTipoTarea(Max(0, FCbTipoTarea.ItemIndex));

  // Hitos y resumenes no aportan duracion propia: el hito no dura y el resumen
  // la recibe agregada de sus hijos en el siguiente recalculo.
  if FData.Kind = wtkTarea then
  begin
    FData.DuracionMin := DuracionEditadaMin;
    FData.MinutosInvertidos := FEdInvertido.Value * 60;
    FData.TrabajoMin := FEdTrabajo.Value * 60;
  end
  else if FData.Kind = wtkHito then
  begin
    FData.DuracionMin := 0;
    FData.MinutosInvertidos := 0;
    FData.TrabajoMin := 0;
  end;

  // Restriccion de fecha (V082). Ya NO se deduce de haber tocado el inicio:
  // se elige explicitamente en su combo. FechaInicioEditada se mantiene solo
  // por compatibilidad con quien aun la lea, pero la restriccion manda.
  FData.ConstraintKind := Max(0, FCbRestriccion.ItemIndex);
  if FEdFechaRestr.Enabled and (FEdFechaRestr.Date > 0) then
    FData.ConstraintDate := FEdFechaRestr.Date
  else
    FData.ConstraintDate := 0;

  FData.FechaInicio := FEdInicio.Date;
  FData.FechaInicioEditada :=
    (FEdInicio.Date > 0) and (Abs(FEdInicio.Date - FInicioOriginal) > 1 / 1440);

  // --- Operarios marcados ---
  // Cerrar la edicion en curso: si el usuario le da a Aceptar con una celda
  // abierta, ese ultimo valor no estaria aun en el DataController.
  if FTvOperarios.DataController.EditState <> [] then
    FTvOperarios.DataController.Post(True);

  // El orden de las filas del grid es el mismo que el del catalogo (no se
  // permite ordenar ni agrupar), asi que el indice de fila identifica al
  // operario.
  Ops := TList<TWbsTaskOperario>.Create;
  try
    for I := 0 to Min(FTvOperarios.DataController.RecordCount,
                      Length(FCatalogo)) - 1 do
    begin
      V := FTvOperarios.DataController.Values[I, FColSel.Index];
      if VarIsNull(V) or VarIsEmpty(V) or (not Boolean(V)) then Continue;

      O := Default(TWbsTaskOperario);
      O.NodeId := FData.NodeId;
      O.OperatorId := FCatalogo[I].OperatorId;
      O.Nombre := FCatalogo[I].Nombre;

      V := FTvOperarios.DataController.Values[I, FColDedic.Index];
      if VarIsNull(V) or VarIsEmpty(V) then D := 100 else D := V;
      V := FTvOperarios.DataController.Values[I, FColHoras.Index];
      if VarIsNull(V) or VarIsEmpty(V) then H := 0 else H := V;
      if (D <= 0) or (D > 100) then D := 100;

      O.Dedicacion := D;
      O.MinutosImputados := Max(0, H) * 60;
      Ops.Add(O);
    end;
    FData.Operarios := Ops.ToArray;
  finally
    Ops.Free;
  end;

  // Las UNIDADES salen de quien ha quedado asignado. Si han cambiado respecto
  // a lo que habia al abrir la ficha, hay que recuadrar la ecuacion antes de
  // devolver los datos: si no, se guardaria un trabajo que ya no corresponde a
  // esta gente. (El repo hace lo mismo en SaveOperarios para los cambios que
  // no pasan por aqui.)
  FData.Unidades := UnidadesDeOperarios(FData.Operarios);
  if FData.Kind = wtkTarea then
  begin
    T := Default(TWbsTask);
    T.Kind := FData.Kind;
    T.TipoTarea := FData.TipoTarea;
    T.DuracionMin := FData.DuracionMin;
    T.TrabajoMin := FData.TrabajoMin;
    T.Unidades := FData.Unidades;
    T := RecalcularTriada(T, wceUnidades);
    FData.DuracionMin := T.DuracionMin;
    FData.TrabajoMin := T.TrabajoMin;
  end;
end;

end.
