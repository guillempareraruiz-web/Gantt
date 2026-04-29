unit uInstallWizard;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Hash,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.DB, Data.Win.ADODB,
  uAppConfig, uErpTypes;

type
  TWizardStep = (wsBienvenida, wsDBPlanner, wsAdmin, wsErp, wsErpConn);

  TfrmInstallWizard = class(TForm)
    pnlHeader: TPanel;
    lblPaso: TLabel;
    lblTituloPaso: TLabel;
    Bevel1: TBevel;
    pnlFooter: TPanel;
    Bevel2: TBevel;
    btnAnterior: TButton;
    btnSiguiente: TButton;
    btnCancelar: TButton;
    pcPasos: TPageControl;
    pnlSimBanner: TPanel;
    lblSimBanner: TLabel;
    tsBienvenida: TTabSheet;
    lblBienvenidaTitulo: TLabel;
    lblBienvenidaTexto: TLabel;
    chkSimulacion: TCheckBox;
    tsDBPlanner: TTabSheet;
    lblPlannerInfo: TLabel;
    pnlDBPlanner: TGroupBox;
    lblPSrv: TLabel;
    lblPDb: TLabel;
    lblPUsr: TLabel;
    lblPPwd: TLabel;
    edPSrv: TEdit;
    edPDb: TEdit;
    chkPWinAuth: TCheckBox;
    edPUsr: TEdit;
    edPPwd: TEdit;
    btnPProbar: TButton;
    btnPCrear: TButton;
    lblPResultado: TLabel;
    tsAdmin: TTabSheet;
    lblAdminInfo: TLabel;
    chkAdminConfirma: TCheckBox;
    lblAdminResultado: TLabel;
    tsErp: TTabSheet;
    lblErpInfo: TLabel;
    lstErps: TListBox;
    pnlErpDetalle: TPanel;
    lblErpNombre: TLabel;
    lblErpEstado: TLabel;
    lblErpDesc: TLabel;
    tsErpConn: TTabSheet;
    lblErpConnInfo: TLabel;
    btnConfigurarErp: TButton;
    btnConfigurarDespues: TButton;
    lblErpConnEstado: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnAnteriorClick(Sender: TObject);
    procedure btnSiguienteClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);

    procedure chkPWinAuthClick(Sender: TObject);
    procedure btnPProbarClick(Sender: TObject);
    procedure btnPCrearClick(Sender: TObject);

    procedure chkAdminConfirmaClick(Sender: TObject);

    procedure lstErpsClick(Sender: TObject);
    procedure lstErpsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);

    procedure btnConfigurarErpClick(Sender: TObject);
    procedure btnConfigurarDespuesClick(Sender: TObject);
    procedure chkSimulacionClick(Sender: TObject);
  private
    FStep: TWizardStep;
    FDBPlannerOk: Boolean;
    FAdminCreado: Boolean;
    FErpSeleccionado: TErpSistema;
    FErpConnHecho: Boolean;
    FSimulacion: Boolean;
    procedure IrAPaso(AStep: TWizardStep);
    procedure ActualizarHeaderYBotones;
    function CollectDBPlannerCfg: TDBConfig;
    procedure ActualizarHabilitacionAuth;
    function BuildPlannerCS(const ACfg: TDBConfig): string;
    function BuildPlannerCSMaster(const ACfg: TDBConfig): string;
    procedure SetPResultado(const AMsg: string; AColor: TColor);
    procedure SetAdminResultado(const AMsg: string; AColor: TColor);
    procedure SetErpConnEstado(const AMsg: string; AColor: TColor);
    procedure RefrescarDetalleErp;
    function CrearUsuarioAdmin(const ACfg: TDBConfig): Boolean;
    function PuedeAvanzar: Boolean;
    function EsUltimoPaso: Boolean;
  public
    class function Execute(AAllowSimulation: Boolean = True): Boolean;
  end;

function NeedsInstallWizard: Boolean;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  uDMPlanner, uDataConnector, uErpPrefsSage200;

function NeedsInstallWizard: Boolean;
var
  Cfg: TDBConfig;
begin
  if not ConfigFileExists then Exit(True);
  Cfg := LoadDBConfig;
  Result := not Cfg.IsValid;
end;

class function TfrmInstallWizard.Execute(AAllowSimulation: Boolean): Boolean;
var
  Frm: TfrmInstallWizard;
begin
  Frm := TfrmInstallWizard.Create(nil);
  try
    Frm.chkSimulacion.Visible := AAllowSimulation;
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

procedure TfrmInstallWizard.FormCreate(Sender: TObject);
var
  Cfg: TDBConfig;
  E: TErpSistema;
begin
  FDBPlannerOk := False;
  FAdminCreado := False;
  FErpConnHecho := False;
  FErpSeleccionado := esSage200;
  FSimulacion := False;
  pnlSimBanner.Visible := False;

  // Pestañas ocultas (controlamos navegación)
  for var I := 0 to pcPasos.PageCount - 1 do
    pcPasos.Pages[I].TabVisible := False;

  // Defaults BBDD Planner
  Cfg := LoadDBConfig;
  if Trim(Cfg.Server) = '' then Cfg.Server := 'localhost\SQLEXPRESS';
  if Trim(Cfg.Database) = '' then Cfg.Database := 'FS';
  edPSrv.Text := Cfg.Server;
  edPDb.Text  := Cfg.Database;
  chkPWinAuth.Checked := Cfg.WindowsAuth;
  edPUsr.Text := Cfg.UserName;
  edPPwd.Text := Cfg.Password;
  ActualizarHabilitacionAuth;

  // Lista ERPs
  lstErps.Items.BeginUpdate;
  try
    for E := Low(TErpSistema) to High(TErpSistema) do
      lstErps.Items.AddObject(ERP_SISTEMAS[E].Nombre, TObject(Ord(E)));
  finally
    lstErps.Items.EndUpdate;
  end;
  lstErps.ItemIndex := Ord(esSage200);
  RefrescarDetalleErp;

  IrAPaso(wsBienvenida);
end;

procedure TfrmInstallWizard.IrAPaso(AStep: TWizardStep);
begin
  FStep := AStep;
  pcPasos.ActivePageIndex := Ord(AStep);
  ActualizarHeaderYBotones;
end;

procedure TfrmInstallWizard.ActualizarHeaderYBotones;
begin
  lblPaso.Caption := Format('Paso %d de 5', [Ord(FStep) + 1]);
  case FStep of
    wsBienvenida: lblTituloPaso.Caption := 'Bienvenida';
    wsDBPlanner:  lblTituloPaso.Caption := 'Conexi'#243'n con la base de datos del Planner';
    wsAdmin:      lblTituloPaso.Caption := 'Crear usuario administrador';
    wsErp:        lblTituloPaso.Caption := 'Selecci'#243'n del ERP origen';
    wsErpConn:    lblTituloPaso.Caption := 'Conexi'#243'n con el ERP';
  end;

  btnAnterior.Enabled := FStep > wsBienvenida;
  btnSiguiente.Enabled := PuedeAvanzar;
  if EsUltimoPaso then
    btnSiguiente.Caption := 'Finalizar'
  else
    btnSiguiente.Caption := 'Siguiente >';
end;

function TfrmInstallWizard.PuedeAvanzar: Boolean;
begin
  case FStep of
    wsBienvenida: Result := True;
    wsDBPlanner:  Result := FDBPlannerOk;
    wsAdmin:      Result := FAdminCreado or chkAdminConfirma.Checked;
    wsErp:        Result := ERP_SISTEMAS[FErpSeleccionado].Disponible;
    wsErpConn:    Result := True;
  else
    Result := False;
  end;
end;

function TfrmInstallWizard.EsUltimoPaso: Boolean;
begin
  Result := FStep = wsErpConn;
end;

procedure TfrmInstallWizard.btnAnteriorClick(Sender: TObject);
begin
  if FStep > wsBienvenida then
    IrAPaso(TWizardStep(Ord(FStep) - 1));
end;

procedure TfrmInstallWizard.btnSiguienteClick(Sender: TObject);
var
  Cfg: TDBConfig;
begin
  case FStep of
    wsBienvenida:
      IrAPaso(wsDBPlanner);

    wsDBPlanner:
    begin
      if not FDBPlannerOk then
      begin
        SetPResultado('Pruebe la conexi'#243'n antes de continuar.', clRed);
        Exit;
      end;
      if FSimulacion then
        SetPResultado('[SIMULACI'#211'N] Se guardar'#237'a la configuraci'#243'n de BBDD.', clOlive)
      else
      begin
        Cfg := CollectDBPlannerCfg;
        SaveDBConfig(Cfg);
      end;
      IrAPaso(wsAdmin);
    end;

    wsAdmin:
    begin
      if FSimulacion then
      begin
        SetAdminResultado('[SIMULACI'#211'N] Se crear'#237'a usuario admin/admin.', clOlive);
        FAdminCreado := True;
      end
      else if not FAdminCreado then
      begin
        Cfg := LoadDBConfig;
        if not CrearUsuarioAdmin(Cfg) then Exit;
        FAdminCreado := True;
      end;
      IrAPaso(wsErp);
    end;

    wsErp:
    begin
      if FSimulacion then
        SetErpConnEstado('[SIMULACI'#211'N] Se guardar'#237'a ERP activo = ' +
          ERP_SISTEMAS[FErpSeleccionado].Codigo + '.', clOlive)
      else
        SaveErpActivo(ERP_SISTEMAS[FErpSeleccionado].Codigo);
      IrAPaso(wsErpConn);
    end;

    wsErpConn:
    begin
      ModalResult := mrOk;
    end;
  end;
end;

procedure TfrmInstallWizard.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmInstallWizard.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if (ModalResult = mrCancel) and FAdminCreado and (not FSimulacion) then
  begin
    CanClose := MessageDlg(
      'Ya se ha creado el usuario admin. '#191'Seguro que desea cancelar?',
      mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  end;
end;

// ─── Paso 2 — BBDD Planner ──────────────────────────────────────────────

procedure TfrmInstallWizard.ActualizarHabilitacionAuth;
begin
  edPUsr.Enabled := not chkPWinAuth.Checked;
  edPPwd.Enabled := not chkPWinAuth.Checked;
end;

procedure TfrmInstallWizard.chkPWinAuthClick(Sender: TObject);
begin
  ActualizarHabilitacionAuth;
end;

function TfrmInstallWizard.CollectDBPlannerCfg: TDBConfig;
begin
  Result.Server      := Trim(edPSrv.Text);
  Result.Database    := Trim(edPDb.Text);
  Result.WindowsAuth := chkPWinAuth.Checked;
  Result.UserName    := Trim(edPUsr.Text);
  Result.Password    := edPPwd.Text;
end;

function TfrmInstallWizard.BuildPlannerCS(const ACfg: TDBConfig): string;
begin
  Result := 'Provider=MSOLEDBSQL.1;Data Source=' + ACfg.Server +
            ';Initial Catalog=' + ACfg.Database;
  if ACfg.WindowsAuth then
    Result := Result + ';Integrated Security=SSPI'
  else
    Result := Result + ';User ID=' + ACfg.UserName + ';Password=' + ACfg.Password;
end;

function TfrmInstallWizard.BuildPlannerCSMaster(const ACfg: TDBConfig): string;
begin
  Result := 'Provider=MSOLEDBSQL.1;Data Source=' + ACfg.Server +
            ';Initial Catalog=master';
  if ACfg.WindowsAuth then
    Result := Result + ';Integrated Security=SSPI'
  else
    Result := Result + ';User ID=' + ACfg.UserName + ';Password=' + ACfg.Password;
end;

procedure TfrmInstallWizard.SetPResultado(const AMsg: string; AColor: TColor);
begin
  lblPResultado.Font.Color := AColor;
  lblPResultado.Caption := AMsg;
  Application.ProcessMessages;
end;

procedure TfrmInstallWizard.btnPProbarClick(Sender: TObject);
var
  Cfg: TDBConfig;
  Conn: TADOConnection;
begin
  Cfg := CollectDBPlannerCfg;
  if not Cfg.IsValid then
  begin
    SetPResultado('Faltan datos de conexi'#243'n.', clRed);
    Exit;
  end;

  SetPResultado('Probando conexi'#243'n...', clBlue);
  Conn := TADOConnection.Create(nil);
  try
    Conn.LoginPrompt := False;
    Conn.ConnectionTimeout := 10;
    Conn.ConnectionString := BuildPlannerCS(Cfg);
    try
      Conn.Connected := True;
      FDBPlannerOk := True;
      SetPResultado('Conexi'#243'n correcta. Pulse Siguiente para continuar.',
        clGreen);
    except
      on E: Exception do
      begin
        FDBPlannerOk := False;
        SetPResultado('Error: ' + E.Message + sLineBreak +
          'Si la base de datos no existe a'#250'n, pulse "Crear base de datos y migrar".',
          clRed);
      end;
    end;
  finally
    Conn.Free;
  end;
  ActualizarHeaderYBotones;
end;

procedure TfrmInstallWizard.btnPCrearClick(Sender: TObject);
var
  Cfg: TDBConfig;
  ConnMaster: TADOConnection;
  Result_: TConnectorResult;
begin
  Cfg := CollectDBPlannerCfg;
  if not Cfg.IsValid then
  begin
    SetPResultado('Faltan datos de conexi'#243'n.', clRed);
    Exit;
  end;

  if FSimulacion then
  begin
    FDBPlannerOk := True;
    SetPResultado('[SIMULACI'#211'N] Se crear'#237'a la BBDD "' + Cfg.Database +
      '" y se aplicar'#237'an las migraciones.', clOlive);
    ActualizarHeaderYBotones;
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    SetPResultado('Conectando a master para crear "' + Cfg.Database + '"...',
      clBlue);
    ConnMaster := TADOConnection.Create(nil);
    try
      ConnMaster.LoginPrompt := False;
      ConnMaster.ConnectionTimeout := 10;
      ConnMaster.ConnectionString := BuildPlannerCSMaster(Cfg);
      try
        ConnMaster.Connected := True;
      except
        on E: Exception do
        begin
          SetPResultado('Error conectando a master: ' + E.Message, clRed);
          Exit;
        end;
      end;

      try
        ConnMaster.Execute(
          'IF DB_ID(''' + Cfg.Database + ''') IS NULL ' +
          'CREATE DATABASE [' + Cfg.Database + ']');
      except
        on E: Exception do
        begin
          SetPResultado('Error creando BBDD: ' + E.Message, clRed);
          Exit;
        end;
      end;
      ConnMaster.Connected := False;
    finally
      ConnMaster.Free;
    end;

    SetPResultado('Base de datos creada. Aplicando migraciones...', clBlue);
    Result_ := DMPlanner.ConnectWith(Cfg.Server, Cfg.Database, Cfg.WindowsAuth,
      Cfg.UserName, Cfg.Password);
    if not Result_.Success then
    begin
      SetPResultado('Error aplicando migraciones: ' + Result_.ErrorMessage,
        clRed);
      Exit;
    end;

    SaveDBConfig(Cfg);
    FDBPlannerOk := True;
    SetPResultado('Base de datos creada y migraciones aplicadas correctamente.',
      clGreen);
  finally
    Screen.Cursor := crDefault;
    ActualizarHeaderYBotones;
  end;
end;

// ─── Paso 3 — Usuario admin ──────────────────────────────────────────────

procedure TfrmInstallWizard.SetAdminResultado(const AMsg: string; AColor: TColor);
begin
  lblAdminResultado.Font.Color := AColor;
  lblAdminResultado.Caption := AMsg;
  Application.ProcessMessages;
end;

procedure TfrmInstallWizard.chkAdminConfirmaClick(Sender: TObject);
begin
  ActualizarHeaderYBotones;
end;

function TfrmInstallWizard.CrearUsuarioAdmin(const ACfg: TDBConfig): Boolean;
var
  Conn: TADOConnection;
  Q: TADOQuery;
  RoleId, CodigoEmpresa: Integer;
  Hash: string;
begin
  Result := False;
  Hash := THashSHA2.GetHashString('admin', SHA256).ToUpper;
  CodigoEmpresa := 1;

  Screen.Cursor := crHourGlass;
  Conn := TADOConnection.Create(nil);
  try
    Conn.LoginPrompt := False;
    Conn.ConnectionString := BuildPlannerCS(ACfg);
    try
      Conn.Connected := True;
    except
      on E: Exception do
      begin
        SetAdminResultado('Error conectando: ' + E.Message, clRed);
        Exit;
      end;
    end;

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := Conn;

      // ¿Ya existe admin?
      Q.SQL.Text :=
        'SELECT COUNT(*) AS N FROM FS_PL_User WHERE Login = ''admin''';
      Q.Open;
      try
        if Q.FieldByName('N').AsInteger > 0 then
        begin
          SetAdminResultado('El usuario admin ya existe. Se mantiene.', clOlive);
          Exit(True);
        end;
      finally
        Q.Close;
      end;

      // Tomar el primer rol disponible (administrador)
      Q.SQL.Text :=
        'SELECT TOP 1 RoleId FROM FS_PL_Role ' +
        'WHERE CodigoEmpresa = ' + IntToStr(CodigoEmpresa) +
        ' ORDER BY RoleId';
      Q.Open;
      try
        if Q.IsEmpty then
        begin
          SetAdminResultado(
            'No hay roles definidos. Ejecute primero el script de roles iniciales.',
            clRed);
          Exit;
        end;
        RoleId := Q.FieldByName('RoleId').AsInteger;
      finally
        Q.Close;
      end;

      Q.SQL.Text :=
        'INSERT INTO FS_PL_User ' +
        '(CodigoEmpresa, Login, PasswordHash, NombreCompleto, Email, RoleId, Activo) ' +
        'VALUES (:CE, ''admin'', :H, ''Administrador'', '''', :R, 1)';
      Q.Parameters.ParamByName('CE').Value := CodigoEmpresa;
      Q.Parameters.ParamByName('H').Value  := Hash;
      Q.Parameters.ParamByName('R').Value  := RoleId;
      try
        Q.ExecSQL;
        SetAdminResultado('Usuario admin creado correctamente.', clGreen);
        Result := True;
      except
        on E: Exception do
          SetAdminResultado('Error creando usuario: ' + E.Message, clRed);
      end;
    finally
      Q.Free;
    end;
  finally
    Conn.Free;
    Screen.Cursor := crDefault;
  end;
end;

// ─── Paso 4 — Selector ERP ──────────────────────────────────────────────

procedure TfrmInstallWizard.lstErpsClick(Sender: TObject);
begin
  if lstErps.ItemIndex < 0 then Exit;
  FErpSeleccionado := TErpSistema(lstErps.ItemIndex);
  RefrescarDetalleErp;
  ActualizarHeaderYBotones;
end;

procedure TfrmInstallWizard.RefrescarDetalleErp;
var
  Info: TErpSistemaInfo;
begin
  Info := ERP_SISTEMAS[FErpSeleccionado];
  lblErpNombre.Caption := Info.Nombre;
  lblErpDesc.Caption   := Info.Descripcion;
  if Info.Disponible then
  begin
    lblErpEstado.Caption := 'Disponible';
    lblErpEstado.Font.Color := clGreen;
  end
  else
  begin
    lblErpEstado.Caption := 'Pr'#243'ximamente';
    lblErpEstado.Font.Color := clGray;
  end;
end;

procedure TfrmInstallWizard.lstErpsDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Lb: TListBox;
  Info: TErpSistemaInfo;
  TxtRect: TRect;
  EstadoTxt: string;
begin
  Lb := Control as TListBox;
  if (Index < 0) or (Index >= Lb.Items.Count) then Exit;
  Info := ERP_SISTEMAS[TErpSistema(Index)];

  if odSelected in State then
    Lb.Canvas.Brush.Color := clHighlight
  else
    Lb.Canvas.Brush.Color := clWindow;
  Lb.Canvas.FillRect(Rect);

  Lb.Canvas.Font.Name := 'Segoe UI';
  Lb.Canvas.Font.Size := 11;
  Lb.Canvas.Font.Style := [fsBold];
  if odSelected in State then
    Lb.Canvas.Font.Color := clHighlightText
  else if Info.Disponible then
    Lb.Canvas.Font.Color := clWindowText
  else
    Lb.Canvas.Font.Color := clGrayText;

  TxtRect := Rect;
  TxtRect.Left := Rect.Left + 12;
  TxtRect.Top := Rect.Top + 8;
  TxtRect.Bottom := TxtRect.Top + 22;
  DrawText(Lb.Canvas.Handle, PChar(Info.Nombre), -1, TxtRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

  Lb.Canvas.Font.Size := 9;
  Lb.Canvas.Font.Style := [];
  if Info.Disponible then EstadoTxt := 'Disponible' else EstadoTxt := 'Pr'#243'ximamente';
  if not (odSelected in State) then
  begin
    if Info.Disponible then
      Lb.Canvas.Font.Color := clGreen
    else
      Lb.Canvas.Font.Color := clGray;
  end;
  TxtRect.Top := Rect.Top + 30;
  TxtRect.Bottom := Rect.Bottom - 4;
  DrawText(Lb.Canvas.Handle, PChar(EstadoTxt), -1, TxtRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);
end;

// ─── Paso 5 — Conexión ERP ──────────────────────────────────────────────

procedure TfrmInstallWizard.SetErpConnEstado(const AMsg: string; AColor: TColor);
begin
  lblErpConnEstado.Font.Color := AColor;
  lblErpConnEstado.Caption := AMsg;
end;

procedure TfrmInstallWizard.btnConfigurarErpClick(Sender: TObject);
begin
  if FSimulacion then
  begin
    SetErpConnEstado('[SIMULACI'#211'N] Se ofrecer'#237'a configurar ' +
      ERP_SISTEMAS[FErpSeleccionado].Nombre + '.', clOlive);
    Exit;
  end;
  case FErpSeleccionado of
    esSage200:
      if TfrmErpPrefsSage200.Execute then
      begin
        FErpConnHecho := True;
        SetErpConnEstado('Conexi'#243'n con Sage 200 configurada.', clGreen);
      end;
  else
    SetErpConnEstado('Configuraci'#243'n para ' +
      ERP_SISTEMAS[FErpSeleccionado].Nombre +
      ' a'#250'n no implementada.', clOlive);
  end;
end;

procedure TfrmInstallWizard.btnConfigurarDespuesClick(Sender: TObject);
begin
  FErpConnHecho := False;
  SetErpConnEstado(
    'Podr'#225' configurar la conexi'#243'n con el ERP m'#225's tarde desde ' +
    'Configuraci'#243'n > Selector de ERP.', clNavy);
end;

procedure TfrmInstallWizard.chkSimulacionClick(Sender: TObject);
begin
  FSimulacion := chkSimulacion.Checked;
  pnlSimBanner.Visible := FSimulacion;
  btnConfigurarErp.Enabled := not FSimulacion;
end;

end.
