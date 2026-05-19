unit uHelpViewer;
// Visor de ayuda contextual reusable para cualquier form.
// Carga Help/<lang>/<TopicKey>.md, lo convierte a RTF y lo muestra
// en un TdxRichEditControl (DevExpress) en modo read-only.
// Sin dependencias ActiveX / IE / Edge / HTML importer.
// Doc: docs/design/AyudaContextual.md
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils,
  System.Classes, System.IOUtils, System.UITypes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  dxCoreClasses, dxRichEdit.Control, dxRichEdit.NativeApi,
  dxRichEdit.Types, dxCore, cxGraphics, dxGDIPlusAPI, dxGDIPlusClasses,
  dxRichEdit.Options, dxRichEdit.Control.SpellChecker,
  dxRichEdit.Dialogs.EventArgs, dxBarBuiltInMenu, cxControls,
  dxRichEdit.Platform.Win.Control, dxRichEdit.Control.Core, dxSkinsCore,
  dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, dxPSGlbl, dxPSUtl, dxPSEngn,
  dxPrnPg, dxBkgnd, dxWrap, dxPrnDev, dxPSCompsProvider, dxPSFillPatterns,
  dxPSEdgePatterns, dxPSPDFExportCore, dxPSPDFExport, cxDrawTextUtils,
  dxPSPrVwStd, dxPSPrVwAdv, dxPSPrVwRibbon, dxPScxPageControlProducer,
  dxPScxEditorProducers, dxPScxExtEditorProducers, cxClasses, dxPSCore,
  dxPSRichEditControlLnk;
type
  TfrmHelpViewer = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    re: TdxRichEditControl;
    lblZoom: TLabel;
    lblZoomValor: TLabel;
    tbZoom: TTrackBar;
    btnImprimir: TButton;
    btnExportar: TButton;
    dxComponentPrinter1: TdxComponentPrinter;
    LblTitulo2: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tbZoomChange(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
  private
    FTopicKey: string;
    FLang: string;
    FTitulo: string;
    FRtf: string;
    procedure LoadRtf;
  end;
  // Helper estatic per instal·lar ajuda contextual a un form:
  //   - boto "?" 28x28 ancorat a la cantonada superior dreta
  //   - F1 obre la mateixa ajuda
  // Crida: THelpViewer.InstallHelp(Self, 'uGestionCalendarios', 'Gestión de calendarios');
  THelpViewer = class
  public
    class procedure Show(const ATopicKey: string;
      const ATitulo: string = ''; const ALang: string = 'es');
    class procedure InstallHelp(AForm: TForm;
      const ATopicKey, ATitulo: string; const ALang: string = 'es');
    class function MarkdownToRtf(const AMd: string): string;
  end;

  // Component intern: emmagatzema la config d'ajuda d'un form i gestiona F1.
  THelpHook = class(TComponent)
  private
    FTopicKey: string;
    FTitulo: string;
    FLang: string;
    procedure FormKeyDownHandler(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BtnAyudaClick(Sender: TObject);
  end;
implementation
{$R *.dfm}
class procedure THelpViewer.Show(const ATopicKey, ATitulo, ALang: string);
var
  F: TfrmHelpViewer;
begin
  F := TfrmHelpViewer.Create(Application);
  try
    F.FTopicKey := ATopicKey;
    F.FTitulo := ATitulo;
    F.FLang := ALang;
    F.ShowModal;
  finally
    F.Free;
  end;
end;
// ----------------------------------------------------------------------------
// MarkdownToRtf: genera RTF amb estil pro.
// Suporta: # H1, ## H2, ### H3, **bold**, *italic*, `code`, - llistes
// Paleta de colors RTF:
//   1: blau corporatiu fort (#1F5C99)   -> 31, 92, 153
//   2: blau mig (#2980B9)                -> 41, 128, 185
//   3: gris-blau (#34495E)              -> 52, 73, 94
//   4: vermell terracota (#C0392B)      -> 192, 57, 43 (code)
//   5: gris fosc text (#2C3E50)         -> 44, 62, 80
//   6: gris fons code (#ECF0F1)         -> 236, 240, 241
// ----------------------------------------------------------------------------
class function THelpViewer.MarkdownToRtf(const AMd: string): string;
const
  RtfHeader =
    '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang3082' +
    '{\fonttbl' +
    '{\f0\fnil\fcharset0 Segoe UI;}' +
    '{\f1\fmodern\fcharset0 Consolas;}' +
    '}' +
    '{\colortbl;' +
    '\red31\green92\blue153;' +     // 1: blau fort
    '\red41\green128\blue185;' +    // 2: blau mig
    '\red52\green73\blue94;' +      // 3: gris-blau
    '\red192\green57\blue43;' +     // 4: vermell terracota
    '\red44\green62\blue80;' +      // 5: gris fosc
    '\red236\green240\blue241;' +   // 6: gris fons
    '\red26\green37\blue47;' +      // 7: gris molt fosc (bold)
    '\red93\green109\blue126;' +    // 8: gris mig (italic)
    '}' +
    '\viewkind4\uc1\pard\sa120\f0\fs22\cf5 ';
  RtfFooter = '}';
var
  Lines: TArray<string>;
  SB: TStringBuilder;
  i: Integer;
  Line: string;
  InList: Boolean;
  // Escapa caracters especials RTF i converteix accents a \u
  function EscapeRtf(const S: string): string;
  var
    j: Integer;
    Ch: Char;
    Code: Integer;
    Buf: TStringBuilder;
  begin
    Buf := TStringBuilder.Create;
    try
      for j := 1 to Length(S) do
      begin
        Ch := S[j];
        case Ch of
          '\': Buf.Append('\\');
          '{': Buf.Append('\{');
          '}': Buf.Append('\}');
        else
          Code := Ord(Ch);
          if Code < 128 then
            Buf.Append(Ch)
          else
          begin
            // Caracter unicode: \uN? on N pot ser negatiu si >32767
            if Code > 32767 then
              Buf.Append('\u' + IntToStr(Code - 65536) + '?')
            else
              Buf.Append('\u' + IntToStr(Code) + '?');
          end;
        end;
      end;
      Result := Buf.ToString;
    finally
      Buf.Free;
    end;
  end;
  // Recorre Buf escapant nomes el text que esta fora de claus {...}
  function EscapeOutsideBraces(const Buf: string): string;
  var
    Out2: TStringBuilder;
    Plain: string;
    Depth, k: Integer;
  begin
    Out2 := TStringBuilder.Create;
    try
      Plain := '';
      Depth := 0;
      for k := 1 to Length(Buf) do
      begin
        if Buf[k] = '{' then
        begin
          if Plain <> '' then
          begin
            Out2.Append(EscapeRtf(Plain));
            Plain := '';
          end;
          Inc(Depth);
          Out2.Append('{');
        end
        else if Buf[k] = '}' then
        begin
          Dec(Depth);
          Out2.Append('}');
        end
        else if Depth = 0 then
          Plain := Plain + Buf[k]
        else
          Out2.Append(Buf[k]);
      end;
      if Plain <> '' then
        Out2.Append(EscapeRtf(Plain));
      Result := Out2.ToString;
    finally
      Out2.Free;
    end;
  end;
  // Aplica **bold**, *italic*, `code` -> RTF inline
  function ApplyInline(const S: string): string;
  var
    P, Q: Integer;
    Buf, Inner: string;
  begin
    Buf := S;
    // **bold** -> {\b\cf7 ...}
    while True do
    begin
      P := Pos('**', Buf);
      if P = 0 then Break;
      Q := PosEx('**', Buf, P + 2);
      if Q = 0 then Break;
      Inner := Copy(Buf, P + 2, Q - P - 2);
      Buf := Copy(Buf, 1, P - 1) +
             '{\b\cf7 ' + EscapeRtf(Inner) + '}' +
             Copy(Buf, Q + 2, MaxInt);
    end;
    // *italic* -> {\i\cf8 ...}
    while True do
    begin
      P := Pos('*', Buf);
      if P = 0 then Break;
      Q := PosEx('*', Buf, P + 1);
      if Q = 0 then Break;
      Inner := Copy(Buf, P + 1, Q - P - 1);
      Buf := Copy(Buf, 1, P - 1) +
             '{\i\cf8 ' + EscapeRtf(Inner) + '}' +
             Copy(Buf, Q + 1, MaxInt);
    end;
    // `code` -> {\f1\cf4\highlight6 ...}
    while True do
    begin
      P := Pos('`', Buf);
      if P = 0 then Break;
      Q := PosEx('`', Buf, P + 1);
      if Q = 0 then Break;
      Inner := Copy(Buf, P + 1, Q - P - 1);
      Buf := Copy(Buf, 1, P - 1) +
             '{\f1\cf4\highlight6 ' + EscapeRtf(Inner) + '}' +
             Copy(Buf, Q + 1, MaxInt);
    end;
    // Escapar nomes el text fora de claus
    Result := EscapeOutsideBraces(Buf);
  end;
begin
  Lines := AMd.Replace(#13#10, #10).Split([#10]);
  SB := TStringBuilder.Create;
  InList := False;
  try
    SB.Append(RtfHeader);
    for i := 0 to High(Lines) do
    begin
      Line := Lines[i].Trim;
      if Line = '' then
      begin
        if InList then
        begin
          SB.Append('\pard\sa120\f0\fs22\cf5 ');
          InList := False;
        end;
        SB.Append('\par ');
        Continue;
      end;
      if Line.StartsWith('### ') then
      begin
        if InList then
        begin
          SB.Append('\pard\sa120\f0\fs22\cf5 ');
          InList := False;
        end;
        // H3: 13pt, semibold, color gris-blau (3)
        SB.Append('\pard\sa80\sb160\f0\fs26\b\cf3 ' +
          ApplyInline(Copy(Line, 5, MaxInt)) + '\b0\par ');
        SB.Append('\pard\sa120\f0\fs22\cf5 ');
      end
      else if Line.StartsWith('## ') then
      begin
        if InList then
        begin
          SB.Append('\pard\sa120\f0\fs22\cf5 ');
          InList := False;
        end;
        // H2: 16pt, bold, color blau mig (2)
        SB.Append('\pard\sa100\sb200\f0\fs32\b\cf2 ' +
          ApplyInline(Copy(Line, 4, MaxInt)) + '\b0\par ');
        SB.Append('\pard\sa120\f0\fs22\cf5 ');
      end
      else if Line.StartsWith('# ') then
      begin
        if InList then
        begin
          SB.Append('\pard\sa120\f0\fs22\cf5 ');
          InList := False;
        end;
        // H1: 22pt, bold, color blau fort (1), border-bottom
        SB.Append('\pard\sa120\sb240\f0\fs44\b\cf1\brdrb\brdrs\brdrw15\brdrcf1\brsp40 ' +
          ApplyInline(Copy(Line, 3, MaxInt)) + '\b0\par ');
        SB.Append('\pard\sa120\f0\fs22\cf5 ');
      end
      else if Line.StartsWith('- ') then
      begin
        if not InList then
          InList := True;
        // Item de lista
        SB.Append('\pard\fi-280\li560\sa60\f0\fs22\cf5 \bullet  ' +
          ApplyInline(Copy(Line, 3, MaxInt)) + '\par ');
      end
      else
      begin
        if InList then
        begin
          SB.Append('\pard\sa120\f0\fs22\cf5 ');
          InList := False;
        end;
        // Paragraf normal
        SB.Append('\pard\sa120\f0\fs22\cf5 ' +
          ApplyInline(Line) + '\par ');
      end;
    end;
    SB.Append(RtfFooter);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;
// ----------------------------------------------------------------------------
// Form
// ----------------------------------------------------------------------------
procedure TfrmHelpViewer.FormShow(Sender: TObject);
var
  Bytes: TBytes;
  MS: TMemoryStream;
begin
  lblTitulo.Caption := 'Ayuda';
  LblTitulo2.Caption := FTitulo;
  LoadRtf;
  // Carregar RTF al TdxRichEditControl (RTF es nadiu, no cal importer extra)
  Bytes := TEncoding.ANSI.GetBytes(FRtf);
  MS := TMemoryStream.Create;
  try
    if Length(Bytes) > 0 then
      MS.WriteBuffer(Bytes[0], Length(Bytes));
    MS.Position := 0;
    re.LoadDocument(MS, TdxRichEditDocumentFormat.Rtf);
  finally
    MS.Free;
  end;
  re.ReadOnly := True;
end;
procedure TfrmHelpViewer.LoadRtf;
var
  Dir, FN, Md: string;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Help\' + FLang;
  FN := Dir + '\' + FTopicKey + '.md';
  if not TFile.Exists(FN) then
  begin
    Md := '# Ayuda no disponible' + sLineBreak + sLineBreak +
          'No se ha encontrado el fichero de ayuda para esta pantalla:' +
          sLineBreak + sLineBreak +
          '`' + FN + '`';
    FRtf := THelpViewer.MarkdownToRtf(Md);
    Exit;
  end;
  try
    Md := TFile.ReadAllText(FN, TEncoding.UTF8);
    FRtf := THelpViewer.MarkdownToRtf(Md);
  except
    on E: Exception do
      FRtf := THelpViewer.MarkdownToRtf('# Error' + sLineBreak + sLineBreak + E.Message);
  end;
end;
procedure TfrmHelpViewer.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;
procedure TfrmHelpViewer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrOk;
end;

procedure TfrmHelpViewer.tbZoomChange(Sender: TObject);
var
  Factor: Double;
begin
  Factor := tbZoom.Position / 100.0;
  lblZoomValor.Caption := IntToStr(tbZoom.Position) + '%';
  try re.Views.PrintLayoutView.ZoomFactor := Factor; except end;
end;

procedure TfrmHelpViewer.btnImprimirClick(Sender: TObject);
var
  Link: TBasedxReportLink;
begin
  try
    Link := dxComponentPrinter1.AddEmptyLinkEx(
      TdxRichEditControlReportLink, re);
    try
      Link.Component := re;
      Link.Preview;
    finally
      dxComponentPrinter1.DeleteLink(Link.Index);
    end;
  except
    on E: Exception do
      ShowMessage('Error al imprimir: ' + E.Message);
  end;
end;

procedure TfrmHelpViewer.btnExportarClick(Sender: TObject);
var
//  SD: TSaveDialog;

  AReportLink: TBasedxReportLink;
begin
  AReportLink := dxComponentPrinter1.AddEmptyLinkEx(
    TdxRichEditControlReportLink,
    re
  );

  AReportLink.Component := re;

  try
    AReportLink.PDFExportOptions.JPEGQuality := 90;
    AReportLink.PDFExportOptions.OpenDocumentAfterExport := True;

    // Mostra di�leg d�opcions PDF + Save As
    AReportLink.ExportToPDF;
  finally
    dxComponentPrinter1.DeleteLink(AReportLink.Index);
  end;

  {SD := TSaveDialog.Create(nil);
  try
    SD.Title := 'Exportar ayuda a PDF';
    SD.Filter := 'PDF (*.pdf)|*.pdf';
    SD.DefaultExt := 'pdf';
    SD.FileName := FTopicKey + '.pdf';
    SD.Options := SD.Options + [ofOverwritePrompt];
    if not SD.Execute then Exit;
    try
      re.ExportDocumentTo(SD.FileName, TdxRichEditDocumentFormat.Pdf);
      ShowMessage('Exportado a:'#13#10 + SD.FileName);
    except
      on E: Exception do
        ShowMessage('Error al exportar: ' + E.Message);
    end;
  finally
    SD.Free;
  end;
  }
end;

// ----------------------------------------------------------------------------
// THelpHook: component intern lligat al form per gestionar F1 + boto "?"
// ----------------------------------------------------------------------------

procedure THelpHook.FormKeyDownHandler(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F1) and (Shift = []) then
  begin
    Key := 0;
    THelpViewer.Show(FTopicKey, FTitulo, FLang);
  end;
end;

procedure THelpHook.BtnAyudaClick(Sender: TObject);
begin
  THelpViewer.Show(FTopicKey, FTitulo, FLang);
end;

// ----------------------------------------------------------------------------
// THelpViewer.InstallHelp: connecta F1 + crea boto "?" a la cantonada
// sup-dreta del form. Reusable a qualsevol form.
// ----------------------------------------------------------------------------

class procedure THelpViewer.InstallHelp(AForm: TForm;
  const ATopicKey, ATitulo, ALang: string);
var
  Hook: THelpHook;
  Btn: TButton;
begin
  if AForm = nil then Exit;

  // Component que viu lligat al form (es destrueix amb ell)
  Hook := THelpHook.Create(AForm);
  Hook.FTopicKey := ATopicKey;
  Hook.FTitulo := ATitulo;
  if ALang = '' then Hook.FLang := 'es' else Hook.FLang := ALang;

  // F1 = obrir ajuda
  AForm.KeyPreview := True;
  AForm.OnKeyDown := Hook.FormKeyDownHandler;

  // Boto "?" 28x28 ancorat a la cantonada sup-dreta del form
  Btn := TButton.Create(Hook);
  Btn.Parent := AForm;
  Btn.SetBounds(AForm.ClientWidth - 36, 8, 28, 28);
  Btn.Anchors := [akTop, akRight];
  Btn.Caption := '?';
  Btn.Font.Name := 'Segoe UI Semibold';
  Btn.Font.Size := 12;
  Btn.Font.Style := [fsBold];
  Btn.ParentFont := False;
  Btn.Hint := 'Ayuda (F1)';
  Btn.ShowHint := True;
  Btn.OnClick := Hook.BtnAyudaClick;
  Btn.BringToFront;
end;

end.
