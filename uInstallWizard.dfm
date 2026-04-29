object frmInstallWizard: TfrmInstallWizard
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Asistente de instalaci'#243'n - FS Planner 2026'
  ClientHeight = 620
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlSimBanner: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 24
    Align = alTop
    BevelOuter = bvNone
    Color = 12189183
    ParentBackground = False
    TabOrder = 3
    Visible = False
    object lblSimBanner: TLabel
      Left = 0
      Top = 0
      Width = 760
      Height = 24
      Align = alClient
      Alignment = taCenter
      Caption = 'MODO SIMULACI'#211'N - no se realizar'#225'n cambios reales'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ExplicitWidth = 296
      ExplicitHeight = 15
    end
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 24
    Width = 760
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblPaso: TLabel
      Left = 16
      Top = 12
      Width = 59
      Height = 15
      Caption = 'Paso 1 de 4'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblTituloPaso: TLabel
      Left = 16
      Top = 32
      Width = 131
      Height = 25
      Caption = 'T'#237'tulo del paso'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Bevel1: TBevel
      Left = 0
      Top = 68
      Width = 760
      Height = 2
      Align = alBottom
      Shape = bsBottomLine
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 565
    Width = 760
    Height = 55
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object Bevel2: TBevel
      Left = 0
      Top = 0
      Width = 760
      Height = 2
      Align = alTop
      Shape = bsTopLine
    end
    object btnAnterior: TButton
      Left = 422
      Top = 12
      Width = 90
      Height = 30
      Caption = '< Anterior'
      TabOrder = 0
      OnClick = btnAnteriorClick
    end
    object btnSiguiente: TButton
      Left = 518
      Top = 12
      Width = 110
      Height = 30
      Caption = 'Siguiente >'
      Default = True
      TabOrder = 1
      OnClick = btnSiguienteClick
    end
    object btnCancelar: TButton
      Left = 654
      Top = 12
      Width = 90
      Height = 30
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 2
      OnClick = btnCancelarClick
    end
  end
  object pcPasos: TPageControl
    Left = 0
    Top = 94
    Width = 760
    Height = 471
    ActivePage = tsBienvenida
    Align = alClient
    TabOrder = 2
    object tsBienvenida: TTabSheet
      Caption = 'Bienvenida'
      object lblBienvenidaTitulo: TLabel
        Left = 32
        Top = 32
        Width = 224
        Height = 21
        Caption = 'Bienvenido a FS Planner 2026'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblBienvenidaTexto: TLabel
        Left = 32
        Top = 70
        Width = 696
        Height = 240
        AutoSize = False
        Caption = 
          'Este asistente le guiar'#225' a trav'#233's de la primera configuraci'#243'n de' +
          'l sistema:'#13#10#13#10'   1. Conexi'#243'n con la base de datos del Planner (S' +
          'QL Server propio).'#13#10'   2. Creaci'#243'n del usuario administrador ini' +
          'cial.'#13#10'   3. Selecci'#243'n del ERP origen de datos.'#13#10'   4. Configura' +
          'ci'#243'n de la conexi'#243'n con el ERP (opcional).'#13#10#13#10'Pulse Siguiente pa' +
          'ra empezar.'
        WordWrap = True
      end
      object chkSimulacion: TCheckBox
        Left = 32
        Top = 402
        Width = 500
        Height = 21
        Caption = 'Modo simulaci'#243'n (no realiza cambios reales)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = chkSimulacionClick
      end
    end
    object tsDBPlanner: TTabSheet
      Caption = 'BBDD Planner'
      ImageIndex = 1
      object lblPlannerInfo: TLabel
        Left = 16
        Top = 12
        Width = 720
        Height = 30
        AutoSize = False
        Caption = 
          'Indique el servidor SQL Server y la base de datos donde se aloja' +
          'r'#225' el Planner. Si la base de datos no existe, se crear'#225' autom'#225'ti' +
          'camente y se aplicar'#225'n las migraciones.'
        WordWrap = True
      end
      object lblPResultado: TLabel
        Left = 16
        Top = 305
        Width = 720
        Height = 100
        AutoSize = False
        WordWrap = True
      end
      object pnlDBPlanner: TGroupBox
        Left = 16
        Top = 50
        Width = 720
        Height = 200
        Caption = 'Conexi'#243'n SQL Server'
        TabOrder = 0
        object lblPSrv: TLabel
          Left = 16
          Top = 28
          Width = 46
          Height = 15
          Caption = 'Servidor:'
        end
        object lblPDb: TLabel
          Left = 16
          Top = 60
          Width = 75
          Height = 15
          Caption = 'Base de datos:'
        end
        object lblPUsr: TLabel
          Left = 16
          Top = 124
          Width = 43
          Height = 15
          Caption = 'Usuario:'
        end
        object lblPPwd: TLabel
          Left = 16
          Top = 156
          Width = 63
          Height = 15
          Caption = 'Contrase'#241'a:'
        end
        object edPSrv: TEdit
          Left = 120
          Top = 24
          Width = 580
          Height = 23
          TabOrder = 0
        end
        object edPDb: TEdit
          Left = 120
          Top = 56
          Width = 580
          Height = 23
          TabOrder = 1
        end
        object chkPWinAuth: TCheckBox
          Left = 120
          Top = 92
          Width = 250
          Height = 17
          Caption = 'Autenticaci'#243'n de Windows'
          TabOrder = 2
          OnClick = chkPWinAuthClick
        end
        object edPUsr: TEdit
          Left = 120
          Top = 120
          Width = 580
          Height = 23
          TabOrder = 3
        end
        object edPPwd: TEdit
          Left = 120
          Top = 152
          Width = 580
          Height = 23
          PasswordChar = '*'
          TabOrder = 4
        end
      end
      object btnPProbar: TButton
        Left = 16
        Top = 260
        Width = 180
        Height = 32
        Caption = 'Probar conexi'#243'n'
        TabOrder = 1
        OnClick = btnPProbarClick
      end
      object btnPCrear: TButton
        Left = 210
        Top = 260
        Width = 250
        Height = 32
        Caption = 'Crear base de datos y migrar'
        TabOrder = 2
        OnClick = btnPCrearClick
      end
    end
    object tsAdmin: TTabSheet
      Caption = 'Usuario admin'
      ImageIndex = 2
      object lblAdminInfo: TLabel
        Left = 32
        Top = 32
        Width = 696
        Height = 113
        AutoSize = False
        Caption = 
          'Se crear'#225' un usuario administrador inicial con los siguientes da' +
          'tos:'#13#10#13#10'   Login: admin'#13#10'   Contrase'#241'a: admin'#13#10#13#10'IMPORTANTE: cam' +
          'bie la contrase'#241'a despu'#233's del primer inicio de sesi'#243'n.'
        WordWrap = True
      end
      object lblAdminResultado: TLabel
        Left = 32
        Top = 170
        Width = 696
        Height = 60
        AutoSize = False
        WordWrap = True
      end
      object chkAdminConfirma: TCheckBox
        Left = 32
        Top = 170
        Width = 500
        Height = 17
        Caption = 'Entiendo y deseo crear el usuario admin/admin.'
        TabOrder = 0
        OnClick = chkAdminConfirmaClick
      end
    end
    object tsErp: TTabSheet
      Caption = 'ERP'
      ImageIndex = 3
      object lblErpInfo: TLabel
        Left = 16
        Top = 12
        Width = 720
        Height = 30
        AutoSize = False
        Caption = 
          'Seleccione el ERP origen de datos. S'#243'lo se podr'#225' elegir un ERP p' +
          'or instalaci'#243'n.'
        WordWrap = True
      end
      object lstErps: TListBox
        Left = 16
        Top = 50
        Width = 320
        Height = 380
        Style = lbOwnerDrawFixed
        ItemHeight = 56
        TabOrder = 0
        OnClick = lstErpsClick
        OnDrawItem = lstErpsDrawItem
      end
      object pnlErpDetalle: TPanel
        Left = 350
        Top = 50
        Width = 386
        Height = 380
        BevelOuter = bvNone
        BorderStyle = bsSingle
        Color = clWindow
        ParentBackground = False
        TabOrder = 1
        object lblErpNombre: TLabel
          Left = 16
          Top = 16
          Width = 113
          Height = 25
          Caption = 'Nombre ERP'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblErpEstado: TLabel
          Left = 16
          Top = 46
          Width = 58
          Height = 15
          Caption = 'Disponible'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGreen
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblErpDesc: TLabel
          Left = 16
          Top = 72
          Width = 350
          Height = 60
          AutoSize = False
          Caption = 'Descripci'#243'n del ERP seleccionado.'
          WordWrap = True
        end
      end
    end
    object tsErpConn: TTabSheet
      Caption = 'Conexi'#243'n ERP'
      ImageIndex = 4
      object lblErpConnInfo: TLabel
        Left = 16
        Top = 12
        Width = 720
        Height = 60
        AutoSize = False
        Caption = 
          'Configure ahora la conexi'#243'n con el ERP seleccionado o pulse "Con' +
          'figurar despu'#233's" para hacerlo m'#225's tarde desde Configuraci'#243'n > Se' +
          'lector de ERP.'
        WordWrap = True
      end
      object lblErpConnEstado: TLabel
        Left = 16
        Top = 130
        Width = 720
        Height = 80
        AutoSize = False
        WordWrap = True
      end
      object btnConfigurarErp: TButton
        Left = 16
        Top = 80
        Width = 280
        Height = 36
        Caption = 'Configurar conexi'#243'n ahora...'
        TabOrder = 0
        OnClick = btnConfigurarErpClick
      end
      object btnConfigurarDespues: TButton
        Left = 310
        Top = 80
        Width = 200
        Height = 36
        Caption = 'Configurar despu'#233's'
        TabOrder = 1
        OnClick = btnConfigurarDespuesClick
      end
    end
  end
end
