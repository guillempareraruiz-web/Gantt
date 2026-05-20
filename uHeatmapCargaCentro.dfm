object frmHeatmapCargaCentro: TfrmHeatmapCargaCentro
  Left = 0
  Top = 0
  Caption = 'Heatmap de carga por centro'
  ClientHeight = 620
  ClientWidth = 1100
  Color = 16317660
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 280
      Height = 25
      Caption = 'Heatmap de carga por centro'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 38
      Width = 700
      Height = 15
      Caption = '% de ocupaci'#243'n por centro y periodo. Datos del plan activo (nodos planificados).'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 64
    Width = 1100
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 1
    object lblGran: TLabel
      Left = 16
      Top = 14
      Width = 60
      Height = 15
      Caption = 'Granularidad:'
    end
    object lblNum: TLabel
      Left = 320
      Top = 14
      Width = 80
      Height = 15
      Caption = 'N'#250'mero periodos:'
    end
    object lblDesde: TLabel
      Left = 520
      Top = 14
      Width = 40
      Height = 15
      Caption = 'Desde:'
    end
    object cmbGranularidad: TComboBox
      Left = 100
      Top = 10
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = ParametrosChange
      Items.Strings = (
        'D'#237'as'
        'Semanas'
        'Meses')
    end
    object spNumPeriodos: TSpinEdit
      Left = 416
      Top = 10
      Width = 80
      Height = 24
      MaxValue = 52
      MinValue = 1
      TabOrder = 1
      Value = 6
      OnChange = ParametrosChange
    end
    object dtDesde: TDateTimePicker
      Left = 568
      Top = 10
      Width = 130
      Height = 23
      TabOrder = 2
      OnChange = ParametrosChange
    end
    object btnRecalcular: TButton
      Left = 720
      Top = 8
      Width = 110
      Height = 28
      Caption = 'Recalcular'
      TabOrder = 3
      OnClick = btnRecalcularClick
    end
  end
  object pnlLegend: TPanel
    Left = 0
    Top = 108
    Width = 1100
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 2
    object pbLegend: TPaintBox
      Left = 16
      Top = 6
      Width = 900
      Height = 28
      OnPaint = pbLegendPaint
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 580
    Width = 1100
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 3
    object btnClose: TButton
      Left = 988
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object sbMatrix: TScrollBox
    Left = 0
    Top = 148
    Width = 1100
    Height = 432
    Align = alClient
    BorderStyle = bsNone
    Color = 16317660
    ParentColor = False
    TabOrder = 4
    object pbMatrix: TPaintBox
      Left = 0
      Top = 0
      Width = 1100
      Height = 432
      OnPaint = pbMatrixPaint
    end
  end
end
