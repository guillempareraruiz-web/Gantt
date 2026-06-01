object frmHeatmapCargaOperario: TfrmHeatmapCargaOperario
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Heatmap de carga por operario'
  ClientHeight = 620
  ClientWidth = 1320
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
    Width = 1320
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 268
      Height = 25
      Caption = 'Heatmap de carga por operario'
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
      Width = 460
      Height = 15
      Caption =
        '% de ocupaci'#243'n por operario y periodo. Datos del plan activo (as' +
        'ignaciones).'
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
    Width = 1320
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      1320
      65)
    object lblGran: TLabel
      Left = 16
      Top = 14
      Width = 71
      Height = 15
      Caption = 'Granularidad:'
    end
    object lblNum: TLabel
      Left = 238
      Top = 15
      Width = 96
      Height = 15
      Caption = 'N'#250'mero periodos:'
    end
    object lblDesde: TLabel
      Left = 368
      Top = 15
      Width = 35
      Height = 15
      Caption = 'Desde:'
    end
    object lblOperarios: TLabel
      Left = 520
      Top = 14
      Width = 53
      Height = 15
      Caption = 'Operarios:'
    end
    object cmbGranularidad: TComboBox
      Left = 16
      Top = 31
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
      Left = 238
      Top = 31
      Width = 107
      Height = 24
      MaxValue = 52
      MinValue = 1
      TabOrder = 1
      Value = 6
      OnChange = ParametrosChange
    end
    object dtDesde: TDateTimePicker
      Left = 368
      Top = 31
      Width = 130
      Height = 23
      Date = 46163.000000000000000000
      Time = 0.322172002313891400
      TabOrder = 2
      OnChange = ParametrosChange
    end
    object btnRecalcular: TButton
      Left = 1186
      Top = 24
      Width = 110
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Recalcular'
      TabOrder = 3
      OnClick = btnRecalcularClick
    end
    object cbOperarios: TcxCheckComboBox
      Left = 520
      Top = 30
      AutoSize = False
      Properties.EmptySelectionText = 'Todos los operarios'
      Properties.Items = <>
      Properties.OnEditValueChanged = cbOperariosChange
      TabOrder = 4
      Height = 25
      Width = 217
    end
  end
  object pnlLegend: TPanel
    Left = 0
    Top = 129
    Width = 1320
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 2
    object pbLegend: TPaintBox
      Left = 16
      Top = 6
      Width = 1280
      Height = 28
      OnPaint = pbLegendPaint
    end
  end
  object sbMatrix: TScrollBox
    Left = 0
    Top = 169
    Width = 1320
    Height = 411
    Align = alClient
    BorderStyle = bsNone
    Color = 16317660
    ParentColor = False
    TabOrder = 4
    object pbMatrix: TPaintBox
      Left = 0
      Top = 0
      Width = 1320
      Height = 411
      OnPaint = pbMatrixPaint
    end
  end
end
