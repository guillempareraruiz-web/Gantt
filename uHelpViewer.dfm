object frmHelpViewer: TfrmHelpViewer
  Left = 0
  Top = 0
  Caption = 'Ayuda'
  ClientHeight = 600
  ClientWidth = 880
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 11
      Width = 46
      Height = 21
      Caption = 'Ayuda'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object LblTitulo2: TLabel
      Left = 69
      Top = 11
      Width = 46
      Height = 21
      Caption = 'Ayuda'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744448
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 556
    Width = 880
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      880
      44)
    object lblZoom: TLabel
      Left = 12
      Top = 14
      Width = 35
      Height = 15
      Caption = 'Zoom:'
    end
    object lblZoomValor: TLabel
      Left = 258
      Top = 14
      Width = 28
      Height = 15
      Caption = '100%'
    end
    object tbZoom: TTrackBar
      Left = 52
      Top = 8
      Width = 200
      Height = 30
      Max = 300
      Frequency = 25
      Position = 100
      ShowSelRange = False
      TabOrder = 1
      OnChange = tbZoomChange
    end
    object btnImprimir: TButton
      Left = 480
      Top = 10
      Width = 90
      Height = 26
      Caption = 'Imprimir...'
      TabOrder = 2
      OnClick = btnImprimirClick
    end
    object btnExportar: TButton
      Left = 576
      Top = 10
      Width = 110
      Height = 26
      Caption = 'Exportar PDF...'
      TabOrder = 3
      OnClick = btnExportarClick
    end
    object btnCerrar: TButton
      Left = 776
      Top = 10
      Width = 90
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Cerrar'
      Default = True
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object re: TdxRichEditControl
    Left = 0
    Top = 44
    Width = 880
    Height = 512
    Align = alClient
    Options.HorizontalRuler.Visibility = Hidden
    Options.VerticalRuler.Visibility = Hidden
    ReadOnly = True
    TabOrder = 2
  end
  object dxComponentPrinter1: TdxComponentPrinter
    Version = 0
    Left = 488
    Top = 8
    PixelsPerInch = 96
  end
end
