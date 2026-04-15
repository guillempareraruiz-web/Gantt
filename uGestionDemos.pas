unit uGestionDemos;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uDemoDataGenerator;

type
  TfrmGestionDemos = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    pnlLeft: TPanel;
    lblSectores: TLabel;
    lbSectores: TListBox;
    pnlRight: TPanel;
    lblDetalle: TLabel;
    memoDetalle: TMemo;
    btnInstalar: TButton;
    btnEliminar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure lbSectoresClick(Sender: TObject);
    procedure btnInstalarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
  private
    FSectores: TArray<TSectorInfo>;
    procedure RefreshDetalle;
    function GetSelectedSector: TSectorDemo;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

procedure TfrmGestionDemos.FormCreate(Sender: TObject);
var
  I: Integer;
  Info: TSectorInfo;
  Estado: string;
  Gen: TDemoDataGenerator;
begin
  FSectores := SectoresDisponibles;
  lbSectores.Items.Clear;

  Gen := TDemoDataGenerator.Create(DMPlanner.ADOConnection);
  try
    for I := 0 to High(FSectores) do
    begin
      Info := FSectores[I];
      if Gen.ExisteDemo(Info.Codigo) then
        Estado := ' [instalada]'
      else
        Estado := '';
      lbSectores.Items.Add(Format('%d - %s%s', [Info.Codigo, Info.SectorNombre, Estado]));
    end;
  finally
    Gen.Free;
  end;

  if lbSectores.Items.Count > 0 then
  begin
    lbSectores.ItemIndex := 0;
    RefreshDetalle;
  end;
end;

procedure TfrmGestionDemos.lbSectoresClick(Sender: TObject);
begin
  RefreshDetalle;
end;

function TfrmGestionDemos.GetSelectedSector: TSectorDemo;
begin
  if (lbSectores.ItemIndex >= 0) and (lbSectores.ItemIndex <= High(FSectores)) then
    Result := FSectores[lbSectores.ItemIndex].Sector
  else
    Result := sdMetalurgico;
end;

procedure TfrmGestionDemos.RefreshDetalle;
var
  Info: TSectorInfo;
begin
  memoDetalle.Lines.Clear;
  if lbSectores.ItemIndex < 0 then Exit;
  if lbSectores.ItemIndex > High(FSectores) then Exit;

  Info := FSectores[lbSectores.ItemIndex];

  memoDetalle.Lines.Add('EMPRESA: ' + Info.Nombre);
  memoDetalle.Lines.Add('C'#211'DIGO:  ' + IntToStr(Info.Codigo));
  memoDetalle.Lines.Add('SECTOR:  ' + Info.SectorNombre);
  memoDetalle.Lines.Add('');

  case Info.Sector of
    sdMetalurgico:
      begin
        memoDetalle.Lines.Add('Contenido:');
        memoDetalle.Lines.Add('  - 5 '#225'reas (Mecanizado, Soldadura, etc.)');
        memoDetalle.Lines.Add('  - 5 departamentos');
        memoDetalle.Lines.Add('  - 10 centros (tornos, fresas, soldadura...)');
        memoDetalle.Lines.Add('  - 14 operarios');
        memoDetalle.Lines.Add('  - Operaciones: TORNEAR, FRESAR, SOLDAR...');
      end;
    sdQuimico:
      begin
        memoDetalle.Lines.Add('Contenido:');
        memoDetalle.Lines.Add('  - 5 '#225'reas (Reactores, Envasado, etc.)');
        memoDetalle.Lines.Add('  - 5 departamentos');
        memoDetalle.Lines.Add('  - 9 centros (reactores, envasadoras...)');
        memoDetalle.Lines.Add('  - 12 operarios');
        memoDetalle.Lines.Add('  - Operaciones: REACTOR, MEZCLAR, ENVASAR...');
      end;
    sdAlimentacion:
      begin
        memoDetalle.Lines.Add('Contenido:');
        memoDetalle.Lines.Add('  - 5 '#225'reas (Preparaci'#243'n, Cocci'#243'n, etc.)');
        memoDetalle.Lines.Add('  - 6 departamentos');
        memoDetalle.Lines.Add('  - 9 centros (hornos, l'#237'neas envasado...)');
        memoDetalle.Lines.Add('  - 14 operarios');
        memoDetalle.Lines.Add('  - Operaciones: COCER, ENVASAR, PALETIZAR...');
      end;
    sdFarmaceutico:
      begin
        memoDetalle.Lines.Add('Contenido:');
        memoDetalle.Lines.Add('  - 6 '#225'reas (Granulaci'#243'n, Compresi'#243'n, QA...)');
        memoDetalle.Lines.Add('  - 7 departamentos');
        memoDetalle.Lines.Add('  - 9 centros (compresoras, blisteadoras...)');
        memoDetalle.Lines.Add('  - 13 operarios');
        memoDetalle.Lines.Add('  - Operaciones: GRANULAR, COMPRIMIR, BLISTEAR...');
      end;
    sdPlasticoInyeccion:
      begin
        memoDetalle.Lines.Add('Contenido:');
        memoDetalle.Lines.Add('  - 5 '#225'reas (Inyecci'#243'n, Soplado, etc.)');
        memoDetalle.Lines.Add('  - 5 departamentos');
        memoDetalle.Lines.Add('  - 9 centros (inyectoras 100-1000T...)');
        memoDetalle.Lines.Add('  - 13 operarios');
        memoDetalle.Lines.Add('  - Operaciones: INYECTAR, SOPLAR, CAMBIO MOLDE...');
      end;
    sdTextil:
      begin
        memoDetalle.Lines.Add('Contenido:');
        memoDetalle.Lines.Add('  - 5 '#225'reas (Corte, Confecci'#243'n, etc.)');
        memoDetalle.Lines.Add('  - 6 departamentos');
        memoDetalle.Lines.Add('  - 8 centros (cortadoras, l'#237'neas costura...)');
        memoDetalle.Lines.Add('  - 14 operarios');
        memoDetalle.Lines.Add('  - Operaciones: CORTAR, COSER, BORDAR...');
      end;
  end;

  memoDetalle.Lines.Add('');
  memoDetalle.Lines.Add('Usuario por defecto: admin / admin');
end;

procedure TfrmGestionDemos.btnInstalarClick(Sender: TObject);
var
  Gen: TDemoDataGenerator;
  Res: TDemoGeneratorResult;
  Sector: TSectorDemo;
  Info: TSectorInfo;
begin
  if lbSectores.ItemIndex < 0 then Exit;
  Sector := GetSelectedSector;
  Info := TSectorInfo.ForSector(Sector);

  if MessageDlg(#191'Instalar datos demo para "' + Info.Nombre + '"?' + sLineBreak +
    'Si ya existen datos de esta empresa, ser'#225'n eliminados primero.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    Gen := TDemoDataGenerator.Create(DMPlanner.ADOConnection);
    try
      Res := Gen.GenerarDemo(Sector);
    finally
      Gen.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  if Res.Success then
  begin
    ShowMessage('Datos demo instalados correctamente.' + sLineBreak + sLineBreak +
      'IMPORTANTE: para ver los datos de esta empresa debes:' + sLineBreak +
      '  1. Cerrar la aplicaci'#243'n' + sLineBreak +
      '  2. Volver a iniciarla' + sLineBreak +
      '  3. En la pantalla de login, seleccionar la empresa:' + sLineBreak +
      '     "' + IntToStr(Info.Codigo) + ' - ' + Info.SectorNombre + '"');
    FormCreate(nil);
  end
  else
    ShowMessage('Error: ' + Res.ErrorMessage);
end;

procedure TfrmGestionDemos.btnEliminarClick(Sender: TObject);
var
  Gen: TDemoDataGenerator;
  Res: TDemoGeneratorResult;
  Info: TSectorInfo;
begin
  if lbSectores.ItemIndex < 0 then Exit;
  Info := FSectores[lbSectores.ItemIndex];

  if MessageDlg(#191'Eliminar TODOS los datos demo de "' + Info.Nombre + '"?',
    mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    Gen := TDemoDataGenerator.Create(DMPlanner.ADOConnection);
    try
      Res := Gen.EliminarDemo(Info.Codigo);
    finally
      Gen.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  if Res.Success then
  begin
    ShowMessage('Datos demo eliminados.');
    FormCreate(nil);
  end
  else
    ShowMessage('Error: ' + Res.ErrorMessage);
end;

end.
