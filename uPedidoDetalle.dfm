object frmPedidoDetalle: TfrmPedidoDetalle
  Left = 0
  Top = 0
  Caption = 'Detalle pedido'
  ClientHeight = 600
  ClientWidth = 1100
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Pedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 36
      Width = 100
      Height = 15
      Caption = 'Detalle'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 560
    Width = 1100
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 992
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cerrar'
      Default = True
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pnlCabecera: TPanel
    Left = 0
    Top = 60
    Width = 1100
    Height = 200
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblCabHeader: TLabel
      Left = 12
      Top = 8
      Width = 80
      Height = 17
      Caption = 'Cabecera'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object gridCabecera: TcxGrid
      Left = 0
      Top = 32
      Width = 1100
      Height = 168
      Align = alClient
      TabOrder = 0
      object tvCabecera: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
      end
      object lvCabecera: TcxGridLevel
        GridView = tvCabecera
      end
    end
  end
  object splitter: TSplitter
    Left = 0
    Top = 260
    Width = 1100
    Height = 4
    Cursor = crVSplit
    Align = alTop
    Color = clBtnFace
    ParentColor = False
  end
  object pnlLineas: TPanel
    Left = 0
    Top = 264
    Width = 1100
    Height = 296
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 4
    object lblLinHeader: TLabel
      Left = 12
      Top = 8
      Width = 80
      Height = 17
      Caption = 'L'#237'neas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object gridLineas: TcxGrid
      Left = 0
      Top = 32
      Width = 1100
      Height = 264
      Align = alClient
      TabOrder = 0
      object tvLineas: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
      end
      object lvLineas: TcxGridLevel
        GridView = tvLineas
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 1040
    Top = 12
  end
end
