object frmFormulaArticuloViewer: TfrmFormulaArticuloViewer
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'F'#243'rmula del art'#237'culo'
  ClientHeight = 640
  ClientWidth = 1200
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 69
      Height = 25
      Caption = 'Art'#237'culo'
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
      Width = 94
      Height = 15
      Caption = 'Visor de escandall'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object pnlKpiComp: TPanel
      Left = 900
      Top = 8
      Width = 138
      Height = 44
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 0
      object lblKpiCompVal: TLabel
        Left = 0
        Top = 3
        Width = 138
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiCompCap: TLabel
        Left = 0
        Top = 26
        Width = 138
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = 'Componentes'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiOper: TPanel
      Left = 1046
      Top = 8
      Width = 138
      Height = 44
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 1
      object lblKpiOperVal: TLabel
        Left = 0
        Top = 3
        Width = 138
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiOperCap: TLabel
        Left = 0
        Top = 26
        Width = 138
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = 'Operaciones'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 600
    Width = 1200
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object lblFooterHint: TLabel
      Left = 12
      Top = 13
      Width = 700
      Height = 15
      AutoSize = False
      Caption =
        'Doble clic en un semielaborado para desplegar su f'#243'rmula.  ' +
        'F1: ayuda.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnClose: TButton
      Left = 1092
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
  object pnlMain: TPanel
    Left = 0
    Top = 60
    Width = 1200
    Height = 540
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object splitter: TSplitter
      Left = 440
      Top = 0
      Height = 540
      ResizeStyle = rsUpdate
    end
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 440
      Height = 540
      Align = alLeft
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object pnlLeftToolbar: TPanel
        Left = 0
        Top = 0
        Width = 440
        Height = 60
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblVersion: TLabel
          Left = 8
          Top = 10
          Width = 47
          Height = 15
          Caption = 'F'#243'rmula:'
        end
        object cmbVersion: TComboBox
          Left = 64
          Top = 6
          Width = 140
          Height = 23
          Style = csDropDownList
          TabOrder = 0
          OnChange = cmbVersionChange
        end
        object chkOnlyWithFormula: TCheckBox
          Left = 8
          Top = 36
          Width = 420
          Height = 21
          Caption = 'Ver solo componentes con f'#243'rmula'
          TabOrder = 1
          OnClick = chkOnlyWithFormulaClick
        end
      end
      object tlFormula: TcxTreeList
        Left = 0
        Top = 60
        Width = 440
        Height = 480
        Align = alClient
        Bands = <
          item
          end>
        LookAndFeel.NativeStyle = False
        LookAndFeel.ScrollbarMode = sbmClassic
        LookAndFeel.SkinName = 'Office2019Colorful'
        Navigator.Buttons.CustomButtons = <>
        OptionsBehavior.CellHints = True
        OptionsBehavior.IncSearch = True
        OptionsCustomizing.BandMoving = False
        OptionsData.Editing = False
        OptionsSelection.CellSelect = False
        OptionsView.ColumnAutoWidth = True
        OptionsView.GridLines = tlglBoth
        OptionsView.ShowRoot = False
        ScrollbarAnnotations.CustomAnnotations = <>
        TabOrder = 1
        OnExpanding = tlFormulaExpanding
        OnFocusedNodeChanged = tlFormulaFocusedNodeChanged
        object colTLArticulo: TcxTreeListColumn
          Caption.Text = 'Estructura'
          MinWidth = 220
          Width = 220
          Position.ColIndex = 0
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colTLTipo: TcxTreeListColumn
          Caption.Text = 'Tipo'
          MinWidth = 80
          Width = 80
          Position.ColIndex = 1
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colTLUnidades: TcxTreeListColumn
          Caption.Text = 'Unidades'
          MinWidth = 80
          Width = 80
          Position.ColIndex = 2
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colTLCentro: TcxTreeListColumn
          Caption.Text = 'Centro'
          MinWidth = 80
          Width = 80
          Position.ColIndex = 3
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
      end
    end
    object pnlRight: TPanel
      Left = 443
      Top = 0
      Width = 757
      Height = 540
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object splitterRight: TSplitter
        Left = 0
        Top = 260
        Width = 757
        Height = 4
        Cursor = crVSplit
        Align = alTop
      end
      object pnlComponentes: TPanel
        Left = 0
        Top = 0
        Width = 757
        Height = 260
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblComponentes: TLabel
          Left = 12
          Top = 6
          Width = 85
          Height = 17
          Caption = 'Componentes'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object gridComponentes: TcxGrid
          Left = 0
          Top = 0
          Width = 757
          Height = 260
          Align = alClient
          TabOrder = 0
          LookAndFeel.ScrollbarMode = sbmClassic
          object tvComponentes: TcxGridTableView
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
          object lvComponentes: TcxGridLevel
            GridView = tvComponentes
          end
        end
      end
      object pnlOperaciones: TPanel
        Left = 0
        Top = 264
        Width = 757
        Height = 276
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object lblOperaciones: TLabel
          Left = 12
          Top = 6
          Width = 76
          Height = 17
          Caption = 'Operaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object gridOperaciones: TcxGrid
          Left = 0
          Top = 0
          Width = 757
          Height = 276
          Align = alClient
          TabOrder = 0
          LookAndFeel.ScrollbarMode = sbmClassic
          object tvOperaciones: TcxGridTableView
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
          object lvOperaciones: TcxGridLevel
            GridView = tvOperaciones
          end
        end
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 1140
    Top = 12
  end
end
