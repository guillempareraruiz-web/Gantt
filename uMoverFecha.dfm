object frmMoverFecha: TfrmMoverFecha
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Mover a fecha'
  ClientHeight = 320
  ClientWidth = 440
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 440
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Mover a fecha'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 36
      Width = 400
      Height = 15
      Caption = 'Elige la fecha destino'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 280
    Width = 440
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 228
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 332
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 60
    Width = 440
    Height = 220
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblOrigen: TLabel
      Left = 24
      Top = 16
      Width = 95
      Height = 15
      Caption = 'Origen de la fecha:'
    end
    object lblFecha: TLabel
      Left = 24
      Top = 150
      Width = 80
      Height = 15
      Caption = 'Fecha destino:'
    end
    object lblHelp: TLabel
      Left = 24
      Top = 184
      Width = 392
      Height = 28
      AutoSize = False
      Caption =
        'La OF/OT/OP se replanificara para empezar (adelante) o acabar (a' +
        'tras) en la fecha indicada, respetando calendario y dependencias' +
        '.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object rbEntrega: TRadioButton
      Left = 40
      Top = 40
      Width = 360
      Height = 17
      Caption = 'Fecha entrega'
      TabOrder = 0
      OnClick = rbEntregaClick
    end
    object rbRecuperacion: TRadioButton
      Left = 40
      Top = 63
      Width = 360
      Height = 17
      Caption = 'Fecha recuperaci'#243'n stock  (pr'#243'ximamente)'
      Enabled = False
      TabOrder = 1
    end
    object rbFinalCola: TRadioButton
      Left = 40
      Top = 86
      Width = 360
      Height = 17
      Caption = 'Fecha final de la cola  (pr'#243'ximamente)'
      Enabled = False
      TabOrder = 2
    end
    object rbManual: TRadioButton
      Left = 40
      Top = 109
      Width = 360
      Height = 17
      Caption = 'Fecha manual'
      TabOrder = 3
      OnClick = rbManualClick
    end
    object dtFecha: TcxDateEdit
      Left = 160
      Top = 146
      Properties.ShowTime = False
      TabOrder = 4
      Width = 150
    end
  end
end
