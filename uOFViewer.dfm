object frmOFViewer: TfrmOFViewer
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Visor de OF'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Padding.Left = 8
  Padding.Top = 8
  Padding.Right = 8
  Padding.Bottom = 8
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pnlClient: TPanel
    Left = 0
    Top = 94
    Width = 1000
    Height = 506
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 43
    ExplicitHeight = 557
    object splMain: TSplitter
      AlignWithMargins = True
      Left = 529
      Top = 3
      Width = 6
      Height = 500
      ExplicitLeft = 520
      ExplicitTop = 0
      ExplicitHeight = 552
    end
    object tlOF: TcxTreeList
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 520
      Height = 500
      Align = alLeft
      Bands = <
        item
        end>
      LookAndFeel.NativeStyle = False
      LookAndFeel.ScrollbarMode = sbmClassic
      LookAndFeel.SkinName = 'Office2019Colorful'
      Navigator.Buttons.CustomButtons = <>
      OptionsBehavior.CellHints = True
      OptionsBehavior.IncSearch = True
      OptionsData.Editing = False
      OptionsSelection.CellSelect = False
      OptionsView.ColumnAutoWidth = True
      OptionsView.GridLines = tlglBoth
      ScrollbarAnnotations.CustomAnnotations = <>
      TabOrder = 0
      OnFocusedNodeChanged = tlOFFocusedNodeChanged
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitHeight = 557
      object colNivel: TcxTreeListColumn
        Caption.Text = 'Nivel'
        MinWidth = 60
        Width = 70
        Position.ColIndex = 0
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colCodigo: TcxTreeListColumn
        Caption.Text = 'C'#243'digo'
        MinWidth = 140
        Width = 160
        Position.ColIndex = 1
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colDescripcion: TcxTreeListColumn
        Caption.Text = 'Descripci'#243'n'
        MinWidth = 180
        Width = 220
        Position.ColIndex = 2
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colEstado: TcxTreeListColumn
        Caption.Text = 'Estado'
        MinWidth = 60
        Width = 70
        Position.ColIndex = 3
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
    end
    object pnlDetalle: TPanel
      Left = 538
      Top = 0
      Width = 462
      Height = 506
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitLeft = 526
      ExplicitWidth = 474
      ExplicitHeight = 557
      object vgDetalle: TcxVerticalGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 456
        Height = 500
        Align = alClient
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2019Colorful'
        OptionsView.RowHeaderWidth = 200
        TabOrder = 0
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 474
        ExplicitHeight = 557
        Version = 1
      end
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 51
    Width = 1000
    Height = 43
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = -3
    object lblDetalle: TLabel
      Left = 541
      Top = 22
      Width = 36
      Height = 15
      Caption = 'Detalle'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object Label1: TLabel
      Left = 3
      Top = 22
      Width = 184
      Height = 15
      Caption = 'Jerarqu'#237'a de la orden de fabricaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 51
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    ExplicitTop = -6
    DesignSize = (
      1000
      51)
    object LblKPIS: TLabel
      Left = 156
      Top = 9
      Width = 176
      Height = 15
      Caption = 'Ordenes de trabajo y operaciones'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object LblOF: TLabel
      Left = 3
      Top = 22
      Width = 124
      Height = 25
      Caption = '2026.AA.3345'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6052910
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object btnExpand: TLabel
      Left = 885
      Top = 30
      Width = 110
      Height = 15
      Cursor = crHandPoint
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      Caption = 'Compactar/Expandir'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsUnderline]
      ParentFont = False
      Layout = tlCenter
      OnClick = btnExpandClick
    end
    object Label3: TLabel
      Left = 3
      Top = 8
      Width = 111
      Height = 15
      Caption = 'Orden de fabricaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object LblOTOP: TLabel
      Left = 156
      Top = 30
      Width = 78
      Height = 15
      Caption = '2026.AA.3345'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6052910
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
  end
end
