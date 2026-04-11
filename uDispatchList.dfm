object DispatchListForm: TDispatchListForm
  Left = 0
  Top = 0
  Caption = 'Lista de Prioridades por Centro'
  ClientHeight = 700
  ClientWidth = 1200
  Color = 15789544
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 17
  object pnlCentres: TPanel
    Left = 0
    Top = 57
    Width = 230
    Height = 643
    Align = alLeft
    BevelOuter = bvNone
    Color = 15263458
    TabOrder = 0
    ExplicitTop = 93
    ExplicitHeight = 607
    object lblCentresTitle: TLabel
      Left = 0
      Top = 0
      Width = 230
      Height = 36
      Align = alTop
      AutoSize = False
      Caption = '   CENTROS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object sbCentres: TScrollBox
      Left = 0
      Top = 36
      Width = 230
      Height = 607
      Align = alClient
      BorderStyle = bsNone
      Color = 15263458
      ParentColor = False
      TabOrder = 0
      ExplicitTop = 21
      ExplicitHeight = 586
    end
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 1
    object lblCentreName: TLabel
      Left = 0
      Top = 0
      Width = 216
      Height = 56
      Align = alLeft
      Caption = '  Seleccione un centro'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -21
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ExplicitHeight = 30
    end
    object lblCount: TLabel
      Left = 216
      Top = 0
      Width = 4
      Height = 56
      Align = alLeft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      ExplicitLeft = 400
      ExplicitHeight = 20
    end
    object pnlEditMode: TPanel
      Left = 220
      Top = 0
      Width = 120
      Height = 56
      Cursor = crHandPoint
      Align = alLeft
      BevelOuter = bvNone
      Color = 15789802
      ParentBackground = False
      TabOrder = 0
      object lblEditMode: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 14
        Width = 114
        Height = 32
        Cursor = crHandPoint
        Margins.Top = 14
        Margins.Bottom = 10
        Align = alClient
        Alignment = taCenter
        Caption = 'Modo Edici'#243'n'
        Color = 15263458
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6710886
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Layout = tlCenter
        ExplicitLeft = 6
        ExplicitTop = 8
        ExplicitHeight = 36
      end
    end
    object pnlPeriodContainer: TPanel
      Left = 856
      Top = 0
      Width = 344
      Height = 56
      Align = alRight
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 1
      object pnlPeriodTodo: TPanel
        Left = 4
        Top = 12
        Width = 80
        Height = 32
        Cursor = crHandPoint
        BevelOuter = bvNone
        Color = 15263458
        ParentBackground = False
        TabOrder = 0
        object lblPeriodTodo: TLabel
          Left = 0
          Top = 0
          Width = 80
          Height = 32
          Cursor = crHandPoint
          Align = alClient
          Alignment = taCenter
          Caption = 'Todo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 5592405
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitWidth = 31
          ExplicitHeight = 17
        end
      end
      object pnlPeriodHoy: TPanel
        Left = 88
        Top = 12
        Width = 80
        Height = 32
        Cursor = crHandPoint
        BevelOuter = bvNone
        Color = 15263458
        ParentBackground = False
        TabOrder = 1
        object lblPeriodHoy: TLabel
          Left = 0
          Top = 0
          Width = 80
          Height = 32
          Cursor = crHandPoint
          Align = alClient
          Alignment = taCenter
          Caption = 'Hoy'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 5592405
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitWidth = 25
          ExplicitHeight = 17
        end
      end
      object pnlPeriodManana: TPanel
        Left = 172
        Top = 12
        Width = 80
        Height = 32
        Cursor = crHandPoint
        BevelOuter = bvNone
        Color = 15263458
        ParentBackground = False
        TabOrder = 2
        object lblPeriodManana: TLabel
          Left = 0
          Top = 0
          Width = 80
          Height = 32
          Cursor = crHandPoint
          Align = alClient
          Alignment = taCenter
          Caption = 'Ma'#241'ana'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 5592405
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitWidth = 49
          ExplicitHeight = 17
        end
      end
      object pnlPeriodSemana: TPanel
        Left = 256
        Top = 12
        Width = 80
        Height = 32
        Cursor = crHandPoint
        BevelOuter = bvNone
        Color = 15263458
        ParentBackground = False
        TabOrder = 3
        object lblPeriodSemana: TLabel
          Left = 0
          Top = 0
          Width = 80
          Height = 32
          Cursor = crHandPoint
          Align = alClient
          Alignment = taCenter
          Caption = 'Semana'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 5592405
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitWidth = 48
          ExplicitHeight = 17
        end
      end
    end
  end
  object pnlSeparator: TPanel
    Left = 0
    Top = 56
    Width = 1200
    Height = 1
    Align = alTop
    BevelOuter = bvNone
    Color = 14737632
    TabOrder = 2
  end
  object pnlContainer: TPanel
    Left = 272
    Top = 120
    Width = 721
    Height = 369
    BevelOuter = bvNone
    Color = clWhite
    DoubleBuffered = True
    ParentBackground = False
    ParentDoubleBuffered = False
    TabOrder = 3
    object pnlColHeader: TPanel
      Left = 0
      Top = 0
      Width = 721
      Height = 36
      Align = alTop
      BevelOuter = bvNone
      Color = 15789544
      ParentBackground = False
      TabOrder = 0
      ExplicitLeft = -545
      ExplicitTop = 57
      ExplicitWidth = 970
    end
  end
end
