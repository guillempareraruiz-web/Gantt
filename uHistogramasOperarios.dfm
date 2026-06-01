object frmHistogramasOperarios: TfrmHistogramasOperarios
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Histogramas de operarios'
  ClientHeight = 660
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
      Width = 230
      Height = 25
      Caption = 'Histogramas de operarios'
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
      Width = 540
      Height = 15
      Caption =
        'Carga, distribuci'#243'n de ocupaci'#243'n y coste laboral del equipo en e' +
        'l periodo seleccionado.'
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
    object lblDesde: TLabel
      Left = 16
      Top = 15
      Width = 35
      Height = 15
      Caption = 'Desde:'
    end
    object lblHasta: TLabel
      Left = 162
      Top = 15
      Width = 33
      Height = 15
      Caption = 'Hasta:'
    end
    object lblOperarios: TLabel
      Left = 310
      Top = 14
      Width = 53
      Height = 15
      Caption = 'Operarios:'
    end
    object dtDesde: TDateTimePicker
      Left = 16
      Top = 31
      Width = 130
      Height = 23
      Date = 46133.000000000000000000
      Time = 0.322172002313891400
      TabOrder = 0
      OnChange = ParametrosChange
    end
    object dtHasta: TDateTimePicker
      Left = 162
      Top = 31
      Width = 130
      Height = 23
      Date = 46163.000000000000000000
      Time = 0.322172002313891400
      TabOrder = 1
      OnChange = ParametrosChange
    end
    object cbOperarios: TcxCheckComboBox
      Left = 310
      Top = 30
      AutoSize = False
      Properties.EmptySelectionText = 'Todos los operarios'
      Properties.Items = <>
      Properties.OnEditValueChanged = cbOperariosChange
      TabOrder = 2
      Height = 25
      Width = 240
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
  end
  object pcTabs: TPageControl
    Left = 0
    Top = 129
    Width = 1320
    Height = 491
    ActivePage = tabCarga
    Align = alClient
    TabOrder = 3
    OnChange = ParametrosChange
    object tabCarga: TTabSheet
      Caption = 'Carga por operario'
      object sbCarga: TScrollBox
        Left = 0
        Top = 0
        Width = 1312
        Height = 461
        Align = alClient
        BorderStyle = bsNone
        Color = 16317660
        ParentColor = False
        TabOrder = 0
        object pbCarga: TPaintBox
          Left = 0
          Top = 0
          Width = 1312
          Height = 461
          OnPaint = pbCargaPaint
        end
      end
    end
    object tabDistrib: TTabSheet
      Caption = 'Distribuci'#243'n de ocupaci'#243'n'
      ImageIndex = 1
      object sbDistrib: TScrollBox
        Left = 0
        Top = 0
        Width = 1312
        Height = 461
        Align = alClient
        BorderStyle = bsNone
        Color = 16317660
        ParentColor = False
        TabOrder = 0
        object pbDistrib: TPaintBox
          Left = 0
          Top = 0
          Width = 1312
          Height = 461
          OnPaint = pbDistribPaint
        end
      end
    end
    object tabCoste: TTabSheet
      Caption = 'Coste laboral'
      ImageIndex = 2
      object sbCoste: TScrollBox
        Left = 0
        Top = 0
        Width = 1312
        Height = 461
        Align = alClient
        BorderStyle = bsNone
        Color = 16317660
        ParentColor = False
        TabOrder = 0
        object pbCoste: TPaintBox
          Left = 0
          Top = 0
          Width = 1312
          Height = 461
          OnPaint = pbCostePaint
        end
      end
    end
  end
end
