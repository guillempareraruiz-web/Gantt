unit uDemoPerfilDlg;

{
  Selector de PERFIL DE DEMOSTRACION.

  Lo abre el boton "Demo 2.0" del toolbar. Su usuario no es un tecnico: es
  quien va a hacer una visita comercial dentro de un rato y necesita que la
  demo hable el idioma del cliente que va a ver.

  Por eso el dialogo ensena, ANTES de generar nada, exactamente que va a salir:
  un esquema de como quedara el plan, las lineas con su capacidad y su tiempo
  de cambio, la ruta de fabricacion y los articulos con sus nombres reales. Si
  al leerlo no le suena al cliente, cambia de perfil o edita el JSON y vuelve
  —y para eso esta el boton que abre la carpeta.

  El ESQUEMA (TEsquemaPlanta) es lo que mas rapido se entiende: dibuja las
  lineas como carriles con bloques de trabajo agrupados y los huecos de cambio
  marcados entre ellos. No es una ilustracion decorativa del sector —una
  fabrica de bolsas dibujada no anadiria nada al texto—: es una miniatura del
  Gantt que el cliente va a ver, que es justo lo que se le esta vendiendo.

  Ver uDemoPerfiles para por que los perfiles describen FORMAS DE PLANTA y no
  sectores.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils,
  System.Classes, System.Math, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Dialogs,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxButtons, cxCheckBox, cxTextEdit, cxMemo,
  cxContainer, cxMaskEdit, cxSpinEdit, cxListBox,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGrid,
  cxGridCustomView, cxData,
  dxSkinsCore, dxSkinsDefaultPainters,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uDemoPerfiles;

type
  // Miniatura del plan que generara el perfil: un carril por linea, bloques de
  // trabajo agrupados por su valor de cambio, y el hueco de preparacion
  // marcado donde ese valor cambia.
  //
  // Se dibuja a partir del perfil real (numero de lineas, MaxLanes, SetupMin,
  // articulos), no es un adorno fijo: cambiar el JSON cambia el dibujo.
  TEsquemaPlanta = class(TCustomControl)
  private
    FPerfil: TDemoPerfil;
    FTiene: Boolean;
    procedure SetPerfil(const V: TDemoPerfil);
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Perfil: TDemoPerfil write SetPerfil;
  end;

  // Ficha de cabecera: las cinco cifras que definen el perfil.
  //
  // Se DIBUJA en vez de componerse con TLabel colocados por pixeles. Con
  // etiquetas, el rotulo de dos lineas se cortaba una y otra vez segun la
  // longitud del texto y el DPI; dibujando se mide antes de pintar y el texto
  // se ajusta o se parte donde toca, no donde cae.
  TFichaPerfil = class(TCustomControl)
  private
    FPerfil: TDemoPerfil;
    FTiene: Boolean;
    procedure SetPerfil(const V: TDemoPerfil);
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Perfil: TDemoPerfil write SetPerfil;
  end;

  TfrmDemoPerfilDlg = class(TForm)
    pnlHeader: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlBottom: TPanel;
    btnGenerar: TcxButton;
    btnCancelar: TcxButton;
    btnCarpeta: TcxButton;
    lblPie: TLabel;
    pnlIzq: TPanel;
    lblPerfiles: TLabel;
    lblNumPerfiles: TLabel;
    lstPerfiles: TcxListBox;
    pnlDer: TPanel;
    lblNombre: TLabel;
    lblDescripcion: TLabel;
    pnlFicha: TPanel;
    lblLineas: TLabel;
    pnlEsquema: TPanel;
    lblRuta: TLabel;
    lblRutaDet: TLabel;
    lblArticulos: TLabel;
    gridArticulos: TcxGrid;
    tvArticulos: TcxGridTableView;
    colArtCodigo: TcxGridColumn;
    colArtDesc: TcxGridColumn;
    colArtSetup: TcxGridColumn;
    lvlArticulos: TcxGridLevel;
    lblCantidad: TLabel;
    seOrdenes: TcxSpinEdit;
    lblOrdenesNota: TLabel;
    chkCrearSetup: TcxCheckBox;
    procedure lstPerfilesClick(Sender: TObject);
    procedure btnCarpetaClick(Sender: TObject);
    // OJO: el ultimo parametro es "var", no "out" (asi lo declara este cxGrid;
    // ver uSincronizarERP). Con "out" no compila.
    procedure tvArticulosStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
  private
    FPerfiles: TDemoPerfilArray;
    FEsquema: TEsquemaPlanta;
    FFicha: TFichaPerfil;
    // Estilo de la columna que provoca el cambio: es LA columna que explica el
    // perfil, asi que se destaca en vez de dejarla como una mas.
    FStyleSetup: TcxStyle;
    procedure CargarLista;
    procedure MostrarPerfil(AIndice: Integer);
    function PerfilSeleccionado: Integer;
  public
    class function Execute(out APerfil: TDemoPerfil;
      out ACrearSetup: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uHelpViewer;

{ TEsquemaPlanta }

constructor TEsquemaPlanta.Create(AOwner: TComponent);
begin
  inherited;
  FTiene := False;
  // DoubleBuffered + csOpaque: sin esto se ve parpadeo al cambiar de perfil.
  // Windows borra el fondo (WM_ERASEBKGND) y despues llega Paint, asi que el
  // ojo capta el blanco intermedio. Con csOpaque se le dice que el control
  // pinta TODA su superficie y no hace falta borrar; DoubleBuffered compone
  // fuera de pantalla y vuelca de una vez.
  DoubleBuffered := True;
  ControlStyle := ControlStyle + [csOpaque];
end;

// Sin esto, VCL sigue mandando el borrado de fondo aunque el control sea
// opaco: es la mitad del parpadeo.
procedure TEsquemaPlanta.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;   // "ya me encargo yo"
end;

procedure TEsquemaPlanta.SetPerfil(const V: TDemoPerfil);
begin
  FPerfil := V;
  FTiene := V.Cargado;
  Invalidate;
end;

procedure TEsquemaPlanta.Paint;
const
  // Paleta de bloques: un color por valor de cambio distinto. Son tonos
  // apagados a proposito, para que lo que destaque sea el HUECO de cambio y no
  // el arcoiris de bloques.
  COLS: array[0..5] of Cardinal = (
    $FF6E93B8, $FF7BA88C, $FFBFA06A, $FF9C87B0, $FF8FA3A8, $FFC0906E);
var
  G: TGPGraphics;
  B, BTxt: TGPSolidBrush;
  P: TGPPen;
  F: TGPFont;
  FF: TGPFontFamily;
  Fmt: TGPStringFormat;
  I, J, NLin, NArt, IdxCol: Integer;
  YFila, AltoFila, XIni, AnchoUtil, X: Single;
  R: TGPRectF;
  Etiq: string;
  Sem, NBloques: Integer;
begin
  G := TGPGraphics.Create(Canvas.Handle);
  FF := TGPFontFamily.Create('Segoe UI');
  F := TGPFont.Create(FF, 7.5, FontStyleRegular, UnitPoint);
  Fmt := TGPStringFormat.Create;
  BTxt := TGPSolidBrush.Create($FF5A5A5A);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);

    B := TGPSolidBrush.Create($FFFFFFFF);
    G.FillRectangle(B, 0, 0, Width, Height);
    B.Free;

    if not FTiene then Exit;

    NLin := Length(FPerfil.Centros);
    if NLin = 0 then Exit;
    NArt := Max(1, Length(FPerfil.Articulos));

    // Se dibujan como mucho 7 carriles: con mas, la miniatura se vuelve
    // ilegible y deja de cumplir su funcion.
    if NLin > 7 then NLin := 7;

    XIni := 92;                       // hueco para el nombre de la linea
    AnchoUtil := Width - XIni - 12;
    AltoFila := Min(18, (Height - 8) / NLin);

    for I := 0 to NLin - 1 do
    begin
      YFila := 4 + I * AltoFila;

      // Nombre de la linea, recortado.
      Etiq := FPerfil.Centros[I].Nombre;
      if Length(Etiq) > 16 then Etiq := Copy(Etiq, 1, 15) + #$2026;
      R := MakeRect(4.0, YFila, 84.0, AltoFila - 3);
      G.DrawString(Etiq, -1, F, R, Fmt, BTxt);

      // Carril de fondo.
      B := TGPSolidBrush.Create($FFF2F0EE);
      G.FillRectangle(B, XIni, YFila, AnchoUtil, AltoFila - 4);
      B.Free;

      // Bloques de trabajo agrupados por valor de cambio. La clave visual es
      // que dentro de un grupo los bloques van PEGADOS (mismo formato: no se
      // paga preparacion) y entre grupos aparece el hueco rayado.
      //
      // Los grupos tienen ANCHO VARIABLE (no todos iguales) porque un patron
      // perfectamente regular se lee como ruido decorativo; con longitudes
      // distintas parece lo que es, un plan.
      X := XIni + 3;
      Sem := 0;
      IdxCol := I mod Min(NArt, Length(COLS));
      NBloques := 2 + ((I + 1) mod 3);   // 2..4 bloques por grupo, segun linea

      while X < XIni + AnchoUtil - 20 do
      begin
        // Un grupo terminado: toca preparacion antes del siguiente.
        if (Sem > 0) and (Sem mod NBloques = 0) then
        begin
          if FPerfil.Centros[I].SetupMin > 0 then
          begin
            // Hueco de cambio: rayado granate, el mismo codigo visual que el
            // Gantt real usa para el tiempo de preparacion.
            P := TGPPen.Create($FFBE1E2D, 1.2);
            for J := 0 to 2 do
              G.DrawLine(P, X + J * 4, YFila + AltoFila - 5,
                            X + J * 4 + 5, YFila + 1);
            P.Free;
            X := X + 15;
          end
          else
            X := X + 4;   // sin regla de cambio, solo un respiro

          // Grupo nuevo: otro color y otra longitud.
          IdxCol := (IdxCol + 1) mod Min(NArt, Length(COLS));
          NBloques := 2 + ((IdxCol + I) mod 3);
          if X >= XIni + AnchoUtil - 20 then Break;
        end;

        B := TGPSolidBrush.Create(COLS[IdxCol]);
        G.FillRectangle(B, X, YFila + 1, 20, AltoFila - 6);
        B.Free;

        X := X + 21;   // 1 px de separacion: pegados, pero distinguibles
        Inc(Sem);
      end;

      // Lineas en paralelo: se insinua con una banda mas fina debajo, para que
      // se distinga un centro secuencial de uno con varios puestos.
      if FPerfil.Centros[I].MaxLanes > 1 then
      begin
        B := TGPSolidBrush.Create($FFD8D4D0);
        G.FillRectangle(B, XIni, YFila + AltoFila - 4, AnchoUtil, 1.5);
        B.Free;
      end;
    end;

    // Leyenda del hueco: sin esto, el rayado no se entiende.
    if Length(FPerfil.Centros) > 0 then
    begin
      P := TGPPen.Create($FFBE1E2D, 1);
      for J := 0 to 3 do
        G.DrawLine(P, Width - 190 + J * 3, Height - 6, Width - 190 + J * 3 + 4,
          Height - 14);
      P.Free;
      R := MakeRect(Width - 172.0, Height - 16.0, 170.0, 14.0);
      G.DrawString('tiempo de cambio de ' + LowerCase(FPerfil.NombreAtributoSetup),
        -1, F, R, Fmt, BTxt);
    end;
  finally
    BTxt.Free;
    Fmt.Free;
    F.Free;
    FF.Free;
    G.Free;
  end;
end;

{ TFichaPerfil }

constructor TFichaPerfil.Create(AOwner: TComponent);
begin
  inherited;
  FTiene := False;
  DoubleBuffered := True;
  ControlStyle := ControlStyle + [csOpaque];
end;

procedure TFichaPerfil.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TFichaPerfil.SetPerfil(const V: TDemoPerfil);
begin
  FPerfil := V;
  FTiene := V.Cargado;
  Invalidate;
end;

procedure TFichaPerfil.Paint;
var
  G: TGPGraphics;
  B: TGPSolidBrush;
  P: TGPPen;
  FF: TGPFontFamily;
  FVal, FRot: TGPFont;
  Fmt: TGPStringFormat;
  I, Secuenciales, ConSetup, TotalSetup, N: Integer;
  Ancho, X: Single;
  R: TGPRectF;

  // Un dato: cifra grande arriba, rotulo debajo. El rotulo se centra y se
  // parte solo si hace falta, dentro del ancho que le toca.
  procedure Dato(AX: Single; const AValor, ARotulo: string; ACol: Cardinal);
  var
    RB: TGPRectF;
    BV, BR: TGPSolidBrush;
  begin
    BV := TGPSolidBrush.Create(ACol);
    BR := TGPSolidBrush.Create($FF8A8580);
    try
      RB := MakeRect(AX + 6, 12.0, Ancho - 12, 26.0);
      G.DrawString(AValor, -1, FVal, RB, Fmt, BV);
      // 32 px = dos lineas completas de 8pt con su interlineado. El rotulo
      // NUNCA se corta a media letra: o cabe, o se parte por la palabra.
      RB := MakeRect(AX + 6, 40.0, Ancho - 12, 32.0);
      G.DrawString(ARotulo, -1, FRot, RB, Fmt, BR);
    finally
      BR.Free;
      BV.Free;
    end;
  end;

begin
  G := TGPGraphics.Create(Canvas.Handle);
  FF := TGPFontFamily.Create('Segoe UI');
  FVal := TGPFont.Create(FF, 13, FontStyleBold, UnitPixel);
  FRot := TGPFont.Create(FF, 11, FontStyleRegular, UnitPixel);
  Fmt := TGPStringFormat.Create;
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);
    Fmt.SetAlignment(StringAlignmentCenter);
    Fmt.SetTrimming(StringTrimmingEllipsisWord);

    B := TGPSolidBrush.Create($FFF4F2F0);
    G.FillRectangle(B, 0, 0, Width, Height);
    B.Free;

    if not FTiene then Exit;

    Secuenciales := 0;
    ConSetup := 0;
    TotalSetup := 0;
    for I := 0 to High(FPerfil.Centros) do
    begin
      if FPerfil.Centros[I].MaxLanes <= 1 then Inc(Secuenciales);
      if FPerfil.Centros[I].SetupMin > 0 then
      begin
        Inc(ConSetup);
        Inc(TotalSetup, FPerfil.Centros[I].SetupMin);
      end;
    end;

    N := 5;
    Ancho := Width / N;

    // Separadores verticales finos entre datos: ordenan la lectura sin cargar.
    P := TGPPen.Create($FFE2DEDA, 1);
    try
      for I := 1 to N - 1 do
        G.DrawLine(P, I * Ancho, 14, I * Ancho, Height - 14);
    finally
      P.Free;
    end;

    X := 0;
    Dato(X, IntToStr(Length(FPerfil.Centros)),
      Format('l'#237'neas, %d en serie', [Secuenciales]), $FF5A5A5A);
    X := X + Ancho;

    Dato(X, IntToStr(FPerfil.OpsPorOrden), 'pasos de ruta', $FF5A5A5A);
    X := X + Ancho;

    // Las dos cifras que DEFINEN el perfil van en color: que dispara el cambio
    // y cuanto cuesta. Es lo que decide si la demo se parece al cliente.
    Dato(X, FPerfil.NombreAtributoSetup, 'dispara el cambio', $FFB4262A);
    X := X + Ancho;

    if ConSetup > 0 then
      Dato(X, Format('%d min', [TotalSetup div ConSetup]),
        Format('de cambio, en %d l'#237'neas', [ConSetup]), $FFB4262A)
    else
      Dato(X, '-', 'sin tiempos de cambio', $FFA0A0A0);
    X := X + Ancho;

    Dato(X, FPerfil.UnidadProduccion, 'unidad de producci'#243'n', $FF5A5A5A);
  finally
    Fmt.Free;
    FRot.Free;
    FVal.Free;
    FF.Free;
    G.Free;
  end;
end;

{ TfrmDemoPerfilDlg }

class function TfrmDemoPerfilDlg.Execute(out APerfil: TDemoPerfil;
  out ACrearSetup: Boolean): Boolean;
var
  F: TfrmDemoPerfilDlg;
  Idx: Integer;
begin
  Result := False;
  APerfil := Default(TDemoPerfil);
  ACrearSetup := False;

  F := TfrmDemoPerfilDlg.Create(nil);
  try
    THelpViewer.InstallHelp(F, 'uDemoPerfilDlg', 'Demostraci'#243'n a medida');

    F.FEsquema := TEsquemaPlanta.Create(F);
    F.FEsquema.Parent := F.pnlEsquema;
    F.FEsquema.Align := alClient;

    F.FFicha := TFichaPerfil.Create(F);
    F.FFicha.Parent := F.pnlFicha;
    F.FFicha.Align := alClient;

    // Mismo granate que el rayado del tiempo de cambio en el esquema y en el
    // Gantt: el ojo relaciona la columna con los huecos de arriba.
    F.FStyleSetup := TcxStyle.Create(F);
    F.FStyleSetup.TextColor := $002A2AB4;
    F.FStyleSetup.Color := $00F2F2FC;
    F.FStyleSetup.Font.Style := [fsBold];

    F.FPerfiles := CargarPerfilesDemo;
    if Length(F.FPerfiles) = 0 then
    begin
      Vcl.Dialogs.MessageDlg(
        'No hay perfiles de demostraci'#243'n disponibles.'#13#10#13#10 +
        'Deber'#237'an estar en:'#13#10 + CarpetaPerfilesDemo,
        mtInformation, [mbOK], 0);
      Exit;
    end;

    F.CargarLista;
    if F.ShowModal <> mrOk then Exit;

    Idx := F.PerfilSeleccionado;
    if Idx < 0 then Exit;

    APerfil := F.FPerfiles[Idx];
    // Lo que haya tecleado manda sobre el valor por defecto del perfil.
    APerfil.NumOrdenes := Round(F.seOrdenes.Value);
    ACrearSetup := F.chkCrearSetup.Checked;
    Result := True;
  finally
    F.Free;
  end;
end;

procedure TfrmDemoPerfilDlg.CargarLista;
var
  I: Integer;
begin
  lstPerfiles.Items.BeginUpdate;
  try
    lstPerfiles.Items.Clear;
    for I := 0 to High(FPerfiles) do
      lstPerfiles.Items.Add(FPerfiles[I].Nombre);
  finally
    lstPerfiles.Items.EndUpdate;
  end;

  lblNumPerfiles.Caption := Format('%d perfiles disponibles',
    [Length(FPerfiles)]);

  if lstPerfiles.Items.Count > 0 then
  begin
    lstPerfiles.ItemIndex := 0;
    MostrarPerfil(0);
  end;
end;

function TfrmDemoPerfilDlg.PerfilSeleccionado: Integer;
begin
  Result := lstPerfiles.ItemIndex;
  if (Result < 0) or (Result > High(FPerfiles)) then Result := -1;
end;

procedure TfrmDemoPerfilDlg.MostrarPerfil(AIndice: Integer);
var
  P: TDemoPerfil;
  I: Integer;
  S: string;
begin
  if (AIndice < 0) or (AIndice > High(FPerfiles)) then Exit;
  P := FPerfiles[AIndice];

  lblNombre.Caption := P.Nombre;
  lblDescripcion.Caption := P.Descripcion;

  if FFicha <> nil then FFicha.Perfil := P;
  if FEsquema <> nil then FEsquema.Perfil := P;

  // Ruta: los pasos en el orden real en que se fabricara.
  S := '';
  for I := 0 to High(P.Operaciones) do
  begin
    if S <> '' then S := S + '   ' + #$2192 + '   ';
    S := S + P.Operaciones[I];
  end;
  lblRutaDet.Caption := S;
  lblRuta.Caption := Format('Ruta de fabricaci'#243'n (%d pasos)',
    [Length(P.Operaciones)]);

  // Articulos: es lo que mas delata si la demo va con el cliente o no. En una
  // rejilla y no en un memo porque las columnas se alinean solas —con texto
  // suelto habia que recurrir a rellenar con espacios— y porque asi se puede
  // DESTACAR la del valor de cambio, que es la que explica el perfil.
  colArtSetup.Caption := P.NombreAtributoSetup;

  tvArticulos.BeginUpdate;
  try
    tvArticulos.DataController.RecordCount := Length(P.Articulos);
    for I := 0 to High(P.Articulos) do
    begin
      tvArticulos.DataController.Values[I, colArtCodigo.Index] :=
        P.Articulos[I].Codigo;
      tvArticulos.DataController.Values[I, colArtDesc.Index] :=
        P.Articulos[I].Descripcion;
      tvArticulos.DataController.Values[I, colArtSetup.Index] :=
        P.Articulos[I].ValorSetup;
    end;
  finally
    tvArticulos.EndUpdate;
  end;

  lblArticulos.Caption := Format(
    'Art'#237'culos de ejemplo (%d)  '#$2022'  as'#237' los ver'#225' el cliente en el plan  ' +
    #$2022'  dos art'#237'culos con el mismo %s NO pagan cambio',
    [Length(P.Articulos), LowerCase(P.NombreAtributoSetup)]);

  seOrdenes.Value := P.NumOrdenes;
  // El generador crea 3 lotes por orden, asi que el total es ordenes x 3 x
  // pasos. Se dice la cifra REAL: quien prepara una visita necesita saber si
  // va a ver 70 barras o 700.
  lblOrdenesNota.Caption := Format(
    'x 3 lotes x %d pasos  ' + #$2248 + '  %d tareas en el plan',
    [P.OpsPorOrden, Round(seOrdenes.Value) * 3 * P.OpsPorOrden]);

  // La casilla de setup solo tiene sentido si el perfil trae tiempos.
  chkCrearSetup.Enabled := False;
  for I := 0 to High(P.Centros) do
    if P.Centros[I].SetupMin > 0 then
    begin
      chkCrearSetup.Enabled := True;
      Break;
    end;
  if chkCrearSetup.Enabled then
    chkCrearSetup.Caption := 'Crear las reglas de tiempo de cambio'
  else
  begin
    chkCrearSetup.Checked := False;
    chkCrearSetup.Caption := 'Este perfil no define tiempos de cambio';
  end;
end;

procedure TfrmDemoPerfilDlg.tvArticulosStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  // Solo la columna del valor de cambio: es la que hace que dos articulos
  // seguidos cuesten o no una preparacion, o sea, la que decide el plan.
  // Destacarla convierte una tabla de datos en una explicacion.
  if (AItem <> nil) and (AItem = colArtSetup) then
    AStyle := FStyleSetup;
end;

procedure TfrmDemoPerfilDlg.lstPerfilesClick(Sender: TObject);
begin
  MostrarPerfil(PerfilSeleccionado);
end;

procedure TfrmDemoPerfilDlg.btnCarpetaClick(Sender: TObject);
begin
  // Abrir la carpeta en el explorador: es la via para que un comercial cree su
  // propio perfil copiando uno existente, sin tocar la aplicacion.
  ShellExecute(0, 'open', PChar(CarpetaPerfilesDemo), nil, nil, SW_SHOWNORMAL);
end;

end.
