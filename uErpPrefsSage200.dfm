object frmErpPrefsSage200: TfrmErpPrefsSage200
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Preferencias de sincronizaci'#243'n - Sage 200'
  ClientHeight = 600
  ClientWidth = 580
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlConexion: TGroupBox
    Left = 12
    Top = 12
    Width = 556
    Height = 200
    Caption = 'Conexi'#243'n SQL Server (Sage 200)'
    TabOrder = 0
    object lblServer: TLabel
      Left = 16
      Top = 28
      Width = 47
      Height = 15
      Caption = 'Servidor:'
    end
    object lblDatabase: TLabel
      Left = 16
      Top = 60
      Width = 73
      Height = 15
      Caption = 'Base de datos:'
    end
    object lblUserName: TLabel
      Left = 16
      Top = 124
      Width = 47
      Height = 15
      Caption = 'Usuario:'
    end
    object lblPassword: TLabel
      Left = 16
      Top = 156
      Width = 67
      Height = 15
      Caption = 'Contrase'#241'a:'
    end
    object edServer: TEdit
      Left = 120
      Top = 24
      Width = 420
      Height = 23
      TabOrder = 0
    end
    object edDatabase: TEdit
      Left = 120
      Top = 56
      Width = 420
      Height = 23
      TabOrder = 1
    end
    object chkWindowsAuth: TCheckBox
      Left = 120
      Top = 92
      Width = 250
      Height = 17
      Caption = 'Autenticaci'#243'n de Windows'
      TabOrder = 2
      OnClick = chkWindowsAuthClick
    end
    object edUserName: TEdit
      Left = 120
      Top = 120
      Width = 420
      Height = 23
      TabOrder = 3
    end
    object edPassword: TEdit
      Left = 120
      Top = 152
      Width = 420
      Height = 23
      PasswordChar = '*'
      TabOrder = 4
    end
  end
  object pnlEmpresa: TGroupBox
    Left = 12
    Top = 220
    Width = 556
    Height = 130
    Caption = 'Empresa Sage 200'
    TabOrder = 1
    object lblGrupoEmpresa: TLabel
      Left = 16
      Top = 28
      Width = 91
      Height = 15
      Caption = 'Grupo de empresa:'
    end
    object lblCodigoEmpresa: TLabel
      Left = 16
      Top = 60
      Width = 100
      Height = 15
      Caption = 'C'#243'digo de empresa:'
    end
    object lblEjercicio: TLabel
      Left = 16
      Top = 92
      Width = 47
      Height = 15
      Caption = 'Ejercicio:'
    end
    object cmbGrupoEmpresa: TComboBox
      Left = 120
      Top = 24
      Width = 300
      Height = 23
      TabOrder = 0
    end
    object btnCargarEmpresas: TButton
      Left = 426
      Top = 23
      Width = 114
      Height = 25
      Caption = 'Cargar empresas'
      TabOrder = 1
      OnClick = btnCargarEmpresasClick
    end
    object cmbCodigoEmpresa: TComboBox
      Left = 120
      Top = 56
      Width = 300
      Height = 23
      TabOrder = 2
    end
    object edEjercicio: TEdit
      Left = 120
      Top = 88
      Width = 100
      Height = 23
      NumbersOnly = True
      TabOrder = 3
    end
  end
  object pnlFiltros: TGroupBox
    Left = 12
    Top = 358
    Width = 556
    Height = 130
    Caption = 'Filtros de sincronizaci'#243'n'
    TabOrder = 2
    object lblFechaDesde: TLabel
      Left = 16
      Top = 28
      Width = 73
      Height = 15
      Caption = 'Fecha desde:'
    end
    object lblFechaHasta: TLabel
      Left = 280
      Top = 28
      Width = 70
      Height = 15
      Caption = 'Fecha hasta:'
    end
    object dtFechaDesde: TDateTimePicker
      Left = 120
      Top = 24
      Width = 130
      Height = 23
      Date = 0d
      Time = 0d
      TabOrder = 0
    end
    object dtFechaHasta: TDateTimePicker
      Left = 384
      Top = 24
      Width = 130
      Height = 23
      Date = 0d
      Time = 0d
      TabOrder = 1
    end
    object chkIncluirFinalizadas: TCheckBox
      Left = 16
      Top = 64
      Width = 400
      Height = 17
      Caption = 'Incluir '#243'rdenes finalizadas'
      TabOrder = 2
    end
    object lblFiltrosNota: TLabel
      Left = 16
      Top = 92
      Width = 524
      Height = 15
      Caption = 'Dejar fechas vac'#237'as significa "sin l'#237'mite".'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
  end
  object pnlPruebas: TPanel
    Left = 12
    Top = 496
    Width = 556
    Height = 50
    BevelOuter = bvNone
    TabOrder = 3
    object btnProbarConexion: TButton
      Left = 0
      Top = 8
      Width = 170
      Height = 32
      Caption = 'Probar conexi'#243'n SQL'
      TabOrder = 0
      OnClick = btnProbarConexionClick
    end
    object btnProbarLectura: TButton
      Left = 184
      Top = 8
      Width = 170
      Height = 32
      Caption = 'Probar lectura ERP'
      TabOrder = 1
      OnClick = btnProbarLecturaClick
    end
    object lblResultado: TLabel
      Left = 364
      Top = 16
      Width = 192
      Height = 15
      AutoSize = False
      Caption = ''
      WordWrap = True
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 555
    Width = 580
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object btnGuardar: TButton
      Left = 364
      Top = 6
      Width = 100
      Height = 32
      Caption = 'Guardar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnGuardarClick
    end
    object btnCancelar: TButton
      Left = 470
      Top = 6
      Width = 100
      Height = 32
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
