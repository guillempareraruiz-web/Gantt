object frmOptimizacionHub: TfrmOptimizacionHub
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Optimizaci'#243'n de corte'
  ClientHeight = 620
  ClientWidth = 1140
  Color = 15790320
  Constraints.MinHeight = 480
  Constraints.MinWidth = 780
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnResize = FormResize
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
      Left = 18
      Top = 10
      Width = 214
      Height = 25
      Caption = 'Optimizaci'#243'n de corte'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 18
      Top = 38
      Width = 320
      Height = 15
      Caption = 'Selecciona la herramienta que quieres utilizar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object sbTools: TcxScrollBox
    Left = 0
    Top = 64
    Width = 1140
    Height = 556
    Align = alClient
    LookAndFeel.Kind = lfFlat
    TabOrder = 1
  end
end
