object frmDBConfig: TfrmDBConfig
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'FSPlanner 2026 - Configuraci'#243'n de Base de Datos'
  ClientHeight = 480
  ClientWidth = 460
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
    Width = 460
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 24
      Top = 14
      Width = 218
      Height = 23
      Caption = 'Configuraci'#243'n de Base de Datos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 24
      Top = 42
      Width = 240
      Height = 15
      Caption = 'Servidor SQL Server y credenciales de acceso'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 70
    Width = 460
    Height = 410
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object lblServer: TLabel
      Left = 30
      Top = 18
      Width = 96
      Height = 15
      Caption = 'Servidor SQL:'
    end
    object lblDatabase: TLabel
      Left = 30
      Top = 70
      Width = 76
      Height = 15
      Caption = 'Base de datos:'
    end
    object lblUserName: TLabel
      Left = 30
      Top = 178
      Width = 43
      Height = 15
      Caption = 'Usuario:'
    end
    object lblPassword: TLabel
      Left = 30
      Top = 230
      Width = 63
      Height = 15
      Caption = 'Contrase'#241'a:'
    end
    object edtServer: TEdit
      Left = 30
      Top = 36
      Width = 400
      Height = 23
      TabOrder = 0
      TextHint = 'SERVIDOR\SQLEXPRESS'
    end
    object edtDatabase: TEdit
      Left = 30
      Top = 88
      Width = 400
      Height = 23
      TabOrder = 1
      TextHint = 'FSPlanner'
    end
    object chkWindowsAuth: TCheckBox
      Left = 30
      Top = 130
      Width = 400
      Height = 24
      Caption = 'Usar autenticaci'#243'n de Windows'
      TabOrder = 2
      OnClick = chkWindowsAuthClick
    end
    object edtUserName: TEdit
      Left = 30
      Top = 196
      Width = 400
      Height = 23
      TabOrder = 3
    end
    object edtPassword: TEdit
      Left = 30
      Top = 248
      Width = 400
      Height = 23
      PasswordChar = '*'
      TabOrder = 4
    end
    object btnTest: TButton
      Left = 30
      Top = 285
      Width = 160
      Height = 28
      Caption = 'Probar conexi'#243'n'
      TabOrder = 5
      OnClick = btnTestClick
    end
    object btnRestablecer: TButton
      Left = 200
      Top = 285
      Width = 160
      Height = 28
      Caption = 'Restablecer'
      TabOrder = 9
      OnClick = btnRestablecerClick
    end
    object Memo1: TMemo
      Left = 30
      Top = 319
      Width = 400
      Height = 50
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 6
      Visible = False
    end
    object btnGuardar: TButton
      Left = 280
      Top = 375
      Width = 150
      Height = 28
      Caption = 'Guardar'
      Default = True
      TabOrder = 7
      OnClick = btnGuardarClick
    end
    object btnCancelar: TButton
      Left = 30
      Top = 375
      Width = 120
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 8
      OnClick = btnCancelarClick
    end
  end
end
