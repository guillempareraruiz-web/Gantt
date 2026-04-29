object frmBacklogSchedParams: TfrmBacklogSchedParams
  Left = 0
  Top = 0
  Caption = 'Par'#225'metros de auto-planificaci'#243'n'
  ClientHeight = 320
  ClientWidth = 460
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 460
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 260
      Height = 25
      Caption = 'Auto-planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 32
      Width = 300
      Height = 15
      Caption = 'Modo, orden y fecha base'
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
    Width = 460
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCalcular: TButton
      Left = 240
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Calcular'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 348
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Cancelar'
      Cancel = True
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 56
    Width = 460
    Height = 224
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblModo: TLabel
      Left = 20
      Top = 16
      Width = 31
      Height = 15
      Caption = 'Modo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblOrden: TLabel
      Left = 20
      Top = 90
      Width = 38
      Height = 15
      Caption = 'Orden'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblFechaBase: TLabel
      Left = 20
      Top = 164
      Width = 60
      Height = 15
      Caption = 'Fecha base'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblFechaHint: TLabel
      Left = 200
      Top = 184
      Width = 240
      Height = 15
      Caption = '(l'#237'mite m'#237'nimo en Forward y Backward)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object rbForward: TRadioButton
      Left = 20
      Top = 36
      Width = 420
      Height = 19
      Caption = 'Forward - planifica a partir de la fecha base hacia el futuro'
      TabOrder = 0
    end
    object rbBackward: TRadioButton
      Left = 20
      Top = 58
      Width = 420
      Height = 19
      Caption = 'Backward - planifica hacia atr'#225's desde FechaCompromiso'
      TabOrder = 1
    end
    object rbOrdenFecha: TRadioButton
      Left = 20
      Top = 110
      Width = 420
      Height = 19
      Caption = 'Por FechaCompromiso ascendente (m'#225's urgentes primero)'
      TabOrder = 2
    end
    object rbOrdenPrio: TRadioButton
      Left = 20
      Top = 132
      Width = 420
      Height = 19
      Caption = 'Por Prioridad descendente'
      TabOrder = 3
    end
    object dtFechaBase: TDateTimePicker
      Left = 20
      Top = 182
      Width = 170
      Height = 23
      TabOrder = 4
    end
  end
end
