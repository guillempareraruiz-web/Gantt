object frmCuadroPlanificacionDelDia: TfrmCuadroPlanificacionDelDia
  Left = 0
  Top = 0
  Caption = 'Cuadro de Planificaci'#243'n del D'#237'a'
  ClientHeight = 700
  ClientWidth = 1300
  Color = 15789544
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 17
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1300
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    object lblTitle: TLabel
      Left = 0
      Top = 0
      Width = 400
      Height = 50
      Align = alLeft
      AutoSize = False
      Caption = '  Cuadro de Planificaci'#243'n del D'#237'a'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -22
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object lblFechaHoy: TLabel
      Left = 400
      Top = 0
      Width = 400
      Height = 50
      Align = alLeft
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4227327
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object pnlHeaderButtons: TPanel
      Left = 1012
      Top = 0
      Width = 288
      Height = 50
      Align = alRight
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object btnLoadDemo: TButton
        Left = 8
        Top = 8
        Width = 160
        Height = 30
        Caption = 'Cargar datos demo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btnLoadDemoClick
      end
      object btnCerrar: TButton
        Left = 180
        Top = 8
        Width = 88
        Height = 30
        Caption = 'Cerrar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnCerrarClick
      end
    end
  end
  object pnlSeparator: TPanel
    Left = 0
    Top = 50
    Width = 1300
    Height = 1
    Align = alTop
    BevelOuter = bvNone
    Color = 14737632
    TabOrder = 1
  end
  object pnlFilterBar: TPanel
    Left = 0
    Top = 51
    Width = 1300
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 2
    object lblFilterCaption: TLabel
      Left = 8
      Top = 0
      Width = 52
      Height = 36
      AutoSize = False
      Caption = 'Centros:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object pnlFilterBtn: TPanel
      Left = 64
      Top = 4
      Width = 260
      Height = 28
      Cursor = crHandPoint
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblFilterText: TLabel
        Left = 8
        Top = 0
        Width = 220
        Height = 28
        Cursor = crHandPoint
        AutoSize = False
        Caption = 'Todos los centros'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 5592405
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object lblFilterArrow: TLabel
        Left = 236
        Top = 0
        Width = 20
        Height = 28
        Cursor = crHandPoint
        Alignment = taCenter
        AutoSize = False
        Caption = #9660
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 8947848
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
    end
  end
  object pnlGlobalKPIs: TPanel
    Left = 0
    Top = 87
    Width = 1300
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = 15789544
    TabOrder = 5
  end
  object pnlTurnoCompare: TPanel
    Left = 0
    Top = 167
    Width = 1300
    Height = 0
    Align = alTop
    BevelOuter = bvNone
    Color = 15789544
    TabOrder = 6
    Visible = False
  end
  object pnlContent: TPanel
    Left = 0
    Top = 167
    Width = 1300
    Height = 505
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    TabOrder = 3
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 672
    Width = 1300
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    Color = 15263458
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 8947848
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    object lblFooterInfo: TLabel
      Left = 8
      Top = 0
      Width = 500
      Height = 28
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
  end
end
