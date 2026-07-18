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
    FTabOperarios: TTabSheet;
    FTabNotas: TTabSheet;

    // --- Cabecera ---
    FLblTarea: TLabel;
    FLblAvanceValor: TLabel;

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

    FData: TWbsTareaEditData;
    FTags: TWbsTagArray;      // copia de trabajo: los chips la modifican
    FOnNuevoTag: TWbsNuevoTagEvent;
    FCatalogo: TWbsOperarioItems;
    FJornadaMin: Integer;
    FInicioOriginal: TDateTime;
    FCargando: Boolean;

    procedure BuildUI;
    procedure BuildTabTarea;
    procedure BuildTabOperarios;
    procedure BuildTabNotas;
    // Empuja los controles que van debajo de las etiquetas cuando los chips
    // ocupan mas de una linea (si no, se solapan con el campo Inicio).
    procedure ReubicarTrasTags;
    procedure CargarDatos;
    procedure VolcarDatos;

    procedure DoDuracionChange(Sender: TObject);
    procedure DoInvertidoChange(Sender: TObject);
    procedure DoTipoChange(Sender: TObject);
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

  MARGEN    = 14;
  ALTO_FILA = 30;
  ANCHO_ETQ = 118;
  ANCHO_ED  = 130;

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
  Pnl: TPanel;
  BtnOK, BtnCancel: TcxButton;
begin
  BorderStyle := bsSizeable;
  Position := poScreenCenter;
  Caption := 'Ficha de tarea';
  ClientWidth := 560;
  ClientHeight := 520;
  Constraints.MinWidth := 480;
  Constraints.MinHeight := 460;
  Color := clWhite;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  // --- Cabecera: nombre de la tarea + avance ---
  Pnl := TPanel.Create(Self);
  Pnl.Parent := Self;
  Pnl.Align := alTop;
  Pnl.Height := 52;
  Pnl.BevelOuter := bvNone;
  Pnl.Color := $00F7F7F7;
  Pnl.ParentBackground := False;

  // OJO: AutoSize := False DESPUES de fijar Caption y fuente, y Align en vez de
  // SetBounds+Anchors. Con SetBounds sobre un panel que aun no tiene su ancho
  // final, el label quedaba de 0 px y el texto no se veia.
  FLblAvanceValor := TLabel.Create(Self);
  FLblAvanceValor.Parent := Pnl;
  FLblAvanceValor.Align := alRight;
  FLblAvanceValor.AlignWithMargins := True;
  FLblAvanceValor.Margins.SetBounds(0, 12, MARGEN, 8);
  FLblAvanceValor.Font.Style := [fsBold];
  FLblAvanceValor.Font.Size := 13;
  FLblAvanceValor.Layout := tlCenter;
  FLblAvanceValor.Alignment := taRightJustify;
  FLblAvanceValor.AutoSize := False;
  FLblAvanceValor.Width := 110;

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

  FTabOperarios := TTabSheet.Create(Self);
  FTabOperarios.PageControl := FPages;
  FTabOperarios.Caption := 'Operarios';

  // Los comentarios van en su propia pestana: ocupaban media ficha y dejaban
  // sin sitio a las etiquetas, que necesitan crecer en varias lineas.
  FTabNotas := TTabSheet.Create(Self);
  FTabNotas.PageControl := FPages;
  FTabNotas.Caption := 'Comentarios';

  BuildTabTarea;
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
  FCbPrioridad.SetBounds(X2 + 74, Y, 110, 22);
  FCbPrioridad.Properties.DropDownListStyle := lsFixedList;
  FCbPrioridad.Properties.Items.Add('Baja');
  FCbPrioridad.Properties.Items.Add('Normal');
  FCbPrioridad.Properties.Items.Add('Alta');
  FCbPrioridad.Properties.Items.Add('Critica');
  Inc(Y, ALTO_FILA);

  // --- Etiquetas (chips estilo Trello) ---
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
  Inc(Y, ALTO_FILA + 8);

  // --- Fechas ---
  LabelEn(FTabTarea, MARGEN, Y, 'Inicio');
  FEdInicio := TcxDateEdit.Create(Self);
  FEdInicio.Parent := FTabTarea;
  FEdInicio.SetBounds(MARGEN + ANCHO_ETQ, Y, ANCHO_ED, 22);

  LabelEn(FTabTarea, X2, Y, 'Fin', 70);
  FEdFin := TcxDateEdit.Create(Self);
  FEdFin.Parent := FTabTarea;
  FEdFin.SetBounds(X2 + 74, Y, 110, 22);
  // El fin lo calcula el motor a partir de inicio + duracion: mostrarlo
  // editable invitaria a introducir una incoherencia.
  FEdFin.Properties.ReadOnly := True;
  FEdFin.Style.Color := $00F0F0F0;
  Inc(Y, ALTO_FILA - 4);

  LabelEn(FTabTarea, MARGEN + ANCHO_ETQ, Y,
    'Fijar el inicio lo convierte en fecha fija del plan.', 320).Font.Color := clGray;
  Inc(Y, 24);

  // --- Duracion en dias / horas / minutos ---
  LabelEn(FTabTarea, MARGEN, Y, 'Duracion estimada');
  FEdDias := TcxSpinEdit.Create(Self);
  FEdDias.Parent := FTabTarea;
  FEdDias.SetBounds(MARGEN + ANCHO_ETQ, Y, 62, 22);
  FEdDias.Properties.MinValue := 0;
  FEdDias.Properties.MaxValue := 9999;
  FEdDias.Properties.OnChange := DoDuracionChange;
  LabelEn(FTabTarea, MARGEN + ANCHO_ETQ + 66, Y, 'd', 16).Font.Color := clGray;

  FEdHoras := TcxSpinEdit.Create(Self);
  FEdHoras.Parent := FTabTarea;
  FEdHoras.SetBounds(MARGEN + ANCHO_ETQ + 84, Y, 56, 22);
  FEdHoras.Properties.MinValue := 0;
  FEdHoras.Properties.MaxValue := 23;
  FEdHoras.Properties.OnChange := DoDuracionChange;
  LabelEn(FTabTarea, MARGEN + ANCHO_ETQ + 144, Y, 'h', 16).Font.Color := clGray;

  FEdMinutos := TcxSpinEdit.Create(Self);
  FEdMinutos.Parent := FTabTarea;
  FEdMinutos.SetBounds(MARGEN + ANCHO_ETQ + 162, Y, 56, 22);
  FEdMinutos.Properties.MinValue := 0;
  FEdMinutos.Properties.MaxValue := 59;
  FEdMinutos.Properties.OnChange := DoDuracionChange;
  LabelEn(FTabTarea, MARGEN + ANCHO_ETQ + 222, Y, 'min', 30).Font.Color := clGray;
  Inc(Y, ALTO_FILA);

  // --- Esfuerzo estimado (trabajo real, distinto de la duracion) ---
  LabelEn(FTabTarea, MARGEN, Y, 'Esfuerzo estimado');
  FEdEsfuerzo := TcxSpinEdit.Create(Self);
  FEdEsfuerzo.Parent := FTabTarea;
  FEdEsfuerzo.SetBounds(MARGEN + ANCHO_ETQ, Y, 90, 22);
  FEdEsfuerzo.Properties.MinValue := 0;
  FEdEsfuerzo.Properties.MaxValue := 99999;
  FEdEsfuerzo.Properties.ValueType := vtFloat;
  LabelEn(FTabTarea, MARGEN + ANCHO_ETQ + 96, Y,
    'horas de trabajo (distinto de la duracion)', 300).Font.Color := clGray;
  Inc(Y, ALTO_FILA);

  // --- Tiempo invertido (V079) ---
  LabelEn(FTabTarea, MARGEN, Y, 'Tiempo invertido');
  FEdInvertido := TcxSpinEdit.Create(Self);
  FEdInvertido.Parent := FTabTarea;
  FEdInvertido.SetBounds(MARGEN + ANCHO_ETQ, Y, 90, 22);
  FEdInvertido.Properties.MinValue := 0;
  FEdInvertido.Properties.MaxValue := 99999;
  FEdInvertido.Properties.ValueType := vtFloat;
  FEdInvertido.Properties.OnChange := DoInvertidoChange;
  LabelEn(FTabTarea, MARGEN + ANCHO_ETQ + 96, Y, 'horas', 60).Font.Color := clGray;
  Inc(Y, ALTO_FILA - 4);

  FLblAviso := TLabel.Create(Self);
  FLblAviso.Parent := FTabTarea;
  FLblAviso.SetBounds(MARGEN + ANCHO_ETQ, Y, 340, 18);
  FLblAviso.Font.Color := $000090FF;
  FLblAviso.Visible := False;

  // Los comentarios ya no estan aqui: tienen su propia pestana (BuildTabNotas).
end;

procedure TfrmWbsTareaEdit.BuildTabOperarios;
var
  Y: Integer;
begin
  Y := MARGEN;

  LabelEn(FTabOperarios, MARGEN, Y,
    'Marca las personas asignadas y ajusta su dedicacion:', 380);
  Inc(Y, 26);

  FGridOperarios := TcxGrid.Create(Self);
  FGridOperarios.Parent := FTabOperarios;
  FGridOperarios.SetBounds(MARGEN, Y, FTabOperarios.Width - MARGEN * 2 - 8,
    FTabOperarios.Height - Y - MARGEN);
  FGridOperarios.Anchors := [akLeft, akTop, akRight, akBottom];

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

    // Habilitar/bloquear campos segun el tipo (hito sin duracion, resumen
    // calculado a partir de sus hijos).
    AplicarTipo;

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
end;

function TfrmWbsTareaEdit.DuracionEditadaMin: Double;
begin
  Result := FEdDias.Value * FJornadaMin + FEdHoras.Value * 60 + FEdMinutos.Value;
end;

procedure TfrmWbsTareaEdit.RefrescarAvance;
var
  Dur, Inv, Av: Double;
begin
  Dur := DuracionEditadaMin;
  Inv := FEdInvertido.Value * 60;
  Av := AvanceTarea(Inv, Dur);

  FLblAvanceValor.Caption := Format('%.0f %%', [Av * 100]);

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
var
  I, Delta: Integer;
  C: TControl;
begin
  // Cuanto ha crecido el bloque de etiquetas respecto al alto de una fila.
  Delta := (FPnlTags.Top + FPnlTags.Height) - (FYTrasTags + ALTO_FILA - 2);
  if Delta = 0 then Exit;

  for I := 0 to FTabTarea.ControlCount - 1 do
  begin
    C := FTabTarea.Controls[I];
    if C = FPnlTags then Continue;
    if C = FLblEtiquetas then Continue;
    // Solo lo que esta por debajo de la banda de etiquetas.
    if C.Top >= FYTrasTags + ALTO_FILA - 2 then
      C.Top := C.Top + Delta;
  end;

  FYTrasTags := FYTrasTags + Delta;
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

  if EsHito then
  begin
    FLblAvisoTipo.Caption := 'Un hito no tiene duracion.';
    FEdDias.Value := 0;
    FEdHoras.Value := 0;
    FEdMinutos.Value := 0;
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
begin
  FData.Kind := TWbsTaskKind(Max(0, FCbTipo.ItemIndex));
  FData.EsHito := FData.Kind = wtkHito;
  FData.Detail.Estado := TWbsTaskEstado(Max(0, FCbEstado.ItemIndex));
  FData.Detail.Prioridad := TWbsTaskPrioridad(Max(0, FCbPrioridad.ItemIndex));
  FData.Tags := FTags;   // los chips ya han ido marcando Asignada
  FData.Detail.Notas := FMemoNotas.Text;
  FData.Detail.HorasEstimadas := FEdEsfuerzo.Value * 60;

  // Hitos y resumenes no aportan duracion propia: el hito no dura y el resumen
  // la recibe agregada de sus hijos en el siguiente recalculo.
  if FData.Kind = wtkTarea then
  begin
    FData.DuracionMin := DuracionEditadaMin;
    FData.MinutosInvertidos := FEdInvertido.Value * 60;
  end
  else if FData.Kind = wtkHito then
  begin
    FData.DuracionMin := 0;
    FData.MinutosInvertidos := 0;
  end;

  // Fecha de inicio: solo cuenta como editada si el usuario la ha CAMBIADO.
  // Es lo que convierte la tarea en fecha fija para el motor.
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
end;

end.
