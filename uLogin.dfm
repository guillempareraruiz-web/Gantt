object frmLogin: TfrmLogin
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'FSPlanner 2026 - Iniciar Sesi'#243'n'
  ClientHeight = 490
  ClientWidth = 400
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 24
      Top = 16
      Width = 147
      Height = 30
      Caption = 'FSPlanner 2026'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 24
      Top = 48
      Width = 148
      Height = 15
      Caption = 'Planificaci'#243'n de Producci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblConfigBD: TLabel
      Left = 250
      Top = 48
      Width = 132
      Height = 15
      Cursor = crHandPoint
      Caption = 'Configurar Base de datos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsUnderline]
      ParentFont = False
      OnClick = lblConfigBDClick
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 80
    Width = 400
    Height = 410
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object lblEmpresa: TLabel
      Left = 50
      Top = 20
      Width = 48
      Height = 15
      Caption = 'Empresa:'
    end
    object lblUsuario: TLabel
      Left = 50
      Top = 80
      Width = 43
      Height = 15
      Caption = 'Usuario:'
    end
    object lblPassword: TLabel
      Left = 50
      Top = 140
      Width = 63
      Height = 15
      Caption = 'Contrase'#241'a:'
    end
    object cmbEmpresa: TComboBox
      Left = 50
      Top = 38
      Width = 300
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object edtUsuario: TEdit
      Left = 50
      Top = 98
      Width = 300
      Height = 23
      TabOrder = 1
    end
    object edtPassword: TEdit
      Left = 50
      Top = 158
      Width = 300
      Height = 23
      PasswordChar = '*'
      TabOrder = 2
    end
    object btnLogin: TButton
      Left = 200
      Top = 337
      Width = 150
      Height = 32
      Caption = 'Iniciar Sesi'#243'n'
      Default = True
      TabOrder = 3
      OnClick = btnLoginClick
    end
    object btnCancelar: TButton
      Left = 50
      Top = 337
      Width = 120
      Height = 32
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 4
      OnClick = btnCancelarClick
    end
    object btnDevAdmin: TButton
      Left = 200
      Top = 375
      Width = 150
      Height = 22
      Caption = '[DEV] Entrar como Admin'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = btnDevAdminClick
    end
    object Memo1: TMemo
      Left = 50
      Top = 187
      Width = 300
      Height = 115
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 6
    end
  end
end
