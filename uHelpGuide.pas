unit uHelpGuide;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxSkinBasic, dxSkinBlack, dxSkinBlue,
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
  dxSkinXmas2008Blue, cxClasses;

type
  TfrmHelpGuide = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    pnlBottom: TPanel;
    btnClose: TButton;
    RichEdit: TRichEdit;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
  private
    procedure LoadContent;
    function BuildRTF: AnsiString;
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

class procedure TfrmHelpGuide.Execute;
var
  F: TfrmHelpGuide;
begin
  F := TfrmHelpGuide.Create(Application);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmHelpGuide.FormCreate(Sender: TObject);
begin
  LoadContent;
  RichEdit.ReadOnly := True;
end;

procedure TfrmHelpGuide.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TfrmHelpGuide.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmHelpGuide.LoadContent;
var
  rtf: AnsiString;
  ms: TMemoryStream;
begin
  rtf := BuildRTF;
  ms := TMemoryStream.Create;
  try
    ms.WriteBuffer(rtf[1], Length(rtf));
    ms.Position := 0;
    RichEdit.Lines.LoadFromStream(ms);
  finally
    ms.Free;
  end;
end;

function TfrmHelpGuide.BuildRTF: AnsiString;

  function S(const ASection: string): AnsiString;
  begin
    Result := AnsiString(
      '\pard\sa60\sb200\f0\fs26\b\cf2 ' + ASection + '\b0\par' + #13#10);
  end;

  function K(const AKeys, ADesc: string): AnsiString;
  begin
    Result := AnsiString(
      '\pard\li360\sa20\f0\fs21\cf3\b ' + AKeys + '\b0\cf0  \emdash  ' + ADesc + '\par' + #13#10);
  end;

  function T(const AText: string): AnsiString;
  begin
    Result := AnsiString(
      '\pard\li360\sa20\f0\fs21\cf0 ' + AText + '\par' + #13#10);
  end;

var
  R: AnsiString;
begin
  R := '{\rtf1\ansi\deff0' + #13#10;
  R := R + '{\fonttbl{\f0\fswiss\fcharset0 Segoe UI;}}' + #13#10;
  R := R + '{\colortbl;\red40\green80\blue140;\red60\green60\blue60;\red20\green90\blue180;}' + #13#10;

  // Titulo
  R := R + '\pard\sa120\f0\fs40\b\cf1 FSPlanner \emdash  Gu\''eda de Referencia R\''e1pida\b0\par' + #13#10;
  R := R + '\pard\sa60\f0\fs21\cf0\par' + #13#10;

  // NAVEGACION
  R := R + S('NAVEGACI\''d3N');
  R := R + K('Bot\''f3n central (arrastrar)', 'Desplazamiento panor\''e1mico (pan)');
  R := R + K('Rueda del rat\''f3n',           'Zoom horizontal (escala de tiempo)');
  R := R + K('Shift + Rueda',                'Scroll vertical');

  // SELECCION
  R := R + S('SELECCI\''d3N DE NODOS');
  R := R + K('Clic izquierdo',            'Seleccionar un nodo');
  R := R + K('Ctrl + Clic',               'A\''f1adir/quitar nodo de la selecci\''f3n m\''faltiple');
  R := R + K('Shift + Arrastrar (vac\''edo)', 'Selecci\''f3n por marquesina (rect\''e1ngulo)');

  // EDICION
  R := R + S('EDICI\''d3N DE NODOS');
  R := R + K('Arrastrar nodo',                    'Mover nodo (cambiar fecha y/o centro)');
  R := R + K('Arrastrar handle izq/der',          'Redimensionar nodo (cambiar inicio/fin)');
  R := R + K('Doble clic en nodo',                'Abrir inspector de nodo');
  R := R + K('Ctrl + Z',                          'Deshacer \''faltima acci\''f3n');
  R := R + K('Ctrl + Y',                          'Rehacer \''faltima acci\''f3n');

  // LINKS
  R := R + S('LINKS / DEPENDENCIAS');
  R := R + K('Ctrl + Arrastrar handle derecho',   'Crear link Finish-to-Start');
  R := R + K('Ctrl + Arrastrar handle izquierdo', 'Crear link Start-to-Start');
  R := R + K('Hover sobre link',                  'Resaltar link (cursor mano)');
  R := R + K('Clic derecho > Editar Links',       'Editar porcentaje y eliminar links');

  // COLORES
  R := R + S('COLORES');
  R := R + K('Clic derecho > Color del nodo',     'Asignar color solo al nodo seleccionado');
  R := R + K('Clic derecho > Color de la OT',     'Asignar color a toda la Orden de Trabajo');
  R := R + K('Clic derecho > Color de la OF',     'Asignar color a toda la Orden de Fabricaci\''f3n');

  // DESPLAZAMIENTO
  R := R + S('DESPLAZAMIENTO TEMPORAL');
  R := R + K('Clic derecho > Mover +1h / -1h',   'Desplazar nodo 1 hora adelante/atr\''e1s');
  R := R + K('Clic derecho > ShiftRow',           'Desplazar todos los nodos de la fila');

  // FECHA BLOQUEO
  R := R + S('FECHA DE BLOQUEO');
  R := R + K('Arrastrar l\''ednea roja vertical',  'Mover la fecha de bloqueo');
  R := R + T('Los nodos anteriores a la fecha de bloqueo no se pueden modificar.');

  // OPERARIOS
  R := R + S('OPERARIOS');
  R := R + K('Clic derecho > Asignar Operarios',  'Asignar operarios a uno o varios nodos');
  R := R + K('Bot\''f3n Gesti\''f3n Operarios',     'Abrir gesti\''f3n completa de operarios');
  R := R + K('Bot\''f3n Filtrar por Operario',      'Filtrar/resaltar nodos de un operario');

  // VISTAS
  R := R + S('VISTAS Y VISUALIZACI\''d3N');
  R := R + K('Selector de Links',             'Mostrar siempre / solo seleccionado / nunca');
  R := R + K('Clic derecho > Calendario',     'Ver calendario laboral del centro');
  R := R + K('Clic derecho > Info',           'Ver informaci\''f3n detallada del nodo');

  // BUSQUEDA
  R := R + S('B\''daSQUEDA Y NAVEGACI\''d3N');
  R := R + K('Barra de b\''fasqueda',               'Buscar nodos por texto (operaci\''f3n, OT, OF...)');
  R := R + K('Botones < >',                        'Navegar entre resultados de b\''fasqueda');
  R := R + K('Botones primer/\''faltimo nodo',      'Ir al primer o \''faltimo nodo del Gantt');

  // Pie
  R := R + '\pard\sa60\f0\fs21\cf0\par' + #13#10;
  R := R + '\pard\li360\f0\fs20\i\cf2 Pulse F1 en cualquier momento para mostrar esta ayuda. Pulse ESC para cerrar.\i0\par' + #13#10;

  R := R + '}';
  Result := R;
end;

end.
