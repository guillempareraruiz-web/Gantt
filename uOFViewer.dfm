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
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pnlClient: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 552
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object tlOF: TcxTreeList
      Left = 0
      Top = 0
      Width = 520
      Height = 552
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
      OptionsView.ShowRoot = True
      ScrollbarAnnotations.CustomAnnotations = <>
      TabOrder = 0
      OnFocusedNodeChanged = tlOFFocusedNodeChanged
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
    object splMain: TSplitter
      Left = 520
      Top = 0
      Width = 6
      Height = 552
      ExplicitLeft = 520
    end
    object pnlDetalle: TPanel
      Left = 526
      Top = 0
      Width = 474
      Height = 552
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object lblDetalle: TLabel
        Left = 0
        Top = 0
        Width = 472
        Height = 24
        Align = alTop
        AutoSize = False
        Caption = '  Detalle'
        Layout = tlCenter
        ExplicitWidth = 44
      end
      object vgDetalle: TcxVerticalGrid
        Left = 0
        Top = 24
        Width = 472
        Height = 528
        Align = alClient
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2019Colorful'
        OptionsView.RowHeaderWidth = 200
        TabOrder = 0
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 552
    Width = 1000
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCerrar: TButton
      Left = 896
      Top = 10
      Width = 90
      Height = 30
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      ModalResult = 2
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
end
