object frmHeatmapEntregasVsCarga: TfrmHeatmapEntregasVsCarga
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Heatmap de entregas vs capacidad'
  ClientHeight = 620
  ClientWidth = 1214
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
    Width = 1214
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 1320
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 298
      Height = 25
      Caption = 'Heatmap de entregas vs capacidad'
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
      Width = 518
      Height = 15
      Caption = 
        '% compromiso por centro y periodo: horas de entrega comprometida' +
        's / capacidad del calendario.'
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
    Width = 1214
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 1
    ExplicitWidth = 1320
    DesignSize = (
      1214
      65)
    object lblGran: TLabel
      Left = 16
      Top = 14
      Width = 71
      Height = 15
      Caption = 'Granularidad:'
    end
    object lblNum: TLabel
      Left = 150
      Top = 15
      Width = 49
      Height = 15
      Caption = 'Periodos:'
    end
    object lblDesde: TLabel
      Left = 227
      Top = 16
      Width = 35
      Height = 15
      Caption = 'Desde:'
    end
    object lblCentros: TLabel
      Left = 379
      Top = 14
      Width = 44
      Height = 15
      Caption = 'Centros:'
    end
    object cmbGranularidad: TComboBox
      Left = 16
      Top = 31
      Width = 110
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
      Left = 150
      Top = 31
      Width = 55
      Height = 24
      MaxValue = 52
      MinValue = 1
      TabOrder = 1
      Value = 6
      OnChange = ParametrosChange
    end
    object dtDesde: TDateTimePicker
      Left = 227
      Top = 32
      Width = 130
      Height = 23
      Date = 46163.000000000000000000
      Time = 0.322172002313891400
      TabOrder = 2
      OnChange = ParametrosChange
    end
    object btnRecalcular: TcxButton
      Left = 1080
      Top = 24
      Width = 110
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Recalcular'
      LookAndFeel.Kind = lfUltraFlat
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      TabOrder = 3
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnRecalcularClick
      ExplicitLeft = 1186
    end
    object cbCentros: TcxCheckComboBox
      Left = 379
      Top = 31
      AutoSize = False
      Properties.EmptySelectionText = 'Todos los centros'
      Properties.EditValueFormat = cvfIndices
      Properties.Items = <>
      Properties.OnEditValueChanged = cbCentrosChange
      TabOrder = 4
      Height = 25
      Width = 217
    end
  end
  object pnlLegend: TPanel
    Left = 0
    Top = 129
    Width = 1214
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 2
    ExplicitWidth = 1320
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
    Width = 1214
    Height = 451
    Align = alClient
    BorderStyle = bsNone
    Color = 16317660
    ParentColor = False
    TabOrder = 3
    ExplicitWidth = 1320
    object pbMatrix: TPaintBox
      Left = 0
      Top = 0
      Width = 1320
      Height = 432
      OnPaint = pbMatrixPaint
    end
  end
end
