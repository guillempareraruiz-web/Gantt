object frmReglasPlanComparativa: TfrmReglasPlanComparativa
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Comparativa de reglas - Planificaci'#243'n'
  ClientHeight = 700
  ClientWidth = 1140
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1140
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 10
      Width = 400
      Height = 30
      Caption = 'Comparativa de reglas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 20
      Top = 42
      Width = 500
      Height = 15
      Caption = 'Mismo plan ordenado con cada regla. Compara los indicadores y elige.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pgc: TcxPageControl
    Left = 0
    Top = 64
    Width = 1140
    Height = 636
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = nil
    Properties.CustomButtons.Buttons = <>
  end
end
