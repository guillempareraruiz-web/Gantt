object frmModulosConfig: TfrmModulosConfig
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'M'#243'dulos contratados'
  ClientHeight = 620
  ClientWidth = 900
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 8
      Width = 196
      Height = 25
      Caption = 'M'#243'dulos contratados'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 16
      Top = 36
      Width = 400
      Height = 15
      Caption = 'Qu'#233' partes del Planner est'#225'n incluidas en la licencia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlNucleo: TPanel
    Left = 0
    Top = 60
    Width = 900
    Height = 66
    Align = alTop
    BevelOuter = bvNone
    Color = 16053492
    ParentBackground = False
    TabOrder = 1
    object lblNucleo: TLabel
      Left = 16
      Top = 10
      Width = 120
      Height = 15
      Caption = 'Siempre incluido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblNucleoDet: TLabel
      Left = 16
      Top = 30
      Width = 860
      Height = 30
      AutoSize = False
      Caption =
        'Gantt de producci'#243'n, centros de trabajo, calendarios y turnos, ba' +
        'cklog, planificaci'#243'n manual y autom'#225'tica, panel de control y con' +
        'exi'#243'n con el ERP.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 580
    Width = 900
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnGuardar: TcxButton
      Left = 676
      Top = 6
      Width = 116
      Height = 28
      Caption = 'Guardar'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 796
      Top = 6
      Width = 96
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
    object lblAviso: TLabel
      Left = 16
      Top = 12
      Width = 600
      Height = 15
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object sbModulos: TScrollBox
    Left = 0
    Top = 126
    Width = 900
    Height = 454
    Align = alClient
    BorderStyle = bsNone
    Color = clWhite
    ParentColor = False
    TabOrder = 2
  end
end
