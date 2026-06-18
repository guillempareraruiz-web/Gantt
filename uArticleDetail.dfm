object frmArticleDetail: TfrmArticleDetail
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Detalle de art'#237'culo'
  ClientHeight = 739
  ClientWidth = 1116
  Color = clBtnFace
  Constraints.MinHeight = 500
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 70
    Width = 1116
    Height = 51
    Align = alTop
    BevelOuter = bvNone
    Color = 6313290
    ParentBackground = False
    TabOrder = 0
    ExplicitTop = 67
    DesignSize = (
      1116
      51)
    object lblArticulo: TLabel
      Left = 12
      Top = 8
      Width = 43
      Height = 13
      Caption = 'Art'#237'culo:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblDescripcion: TLabel
      Left = 70
      Top = 30
      Width = 346
      Height = 15
      AutoSize = False
      Caption = 'Desc'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblAlmacenes: TLabel
      Left = 552
      Top = 5
      Width = 57
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Almacenes:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblFecha: TLabel
      Left = 825
      Top = 3
      Width = 92
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Fecha proyecci'#243'n:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object edArticulo: TEdit
      Left = 69
      Top = 6
      Width = 180
      Height = 23
      TabOrder = 0
    end
    object btnBuscarArticulo: TButton
      Left = 219
      Top = 8
      Width = 28
      Height = 19
      Caption = '...'
      TabOrder = 1
      OnClick = btnBuscarArticuloClick
    end
    object ccbAlmacenes: TcxCheckComboBox
      Left = 552
      Top = 20
      Anchors = [akTop, akRight]
      Properties.Items = <>
      TabOrder = 2
      Width = 265
    end
    object dtFecha: TDateTimePicker
      Left = 825
      Top = 19
      Width = 130
      Height = 23
      Anchors = [akTop, akRight]
      Date = 44562.000000000000000000
      Time = 44562.000000000000000000
      TabOrder = 3
    end
    object btnCalcular: TButton
      Left = 989
      Top = 18
      Width = 116
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Calcular'
      Default = True
      TabOrder = 4
      OnClick = btnCalcularClick
    end
    object Edit1: TEdit
      Left = 264
      Top = 6
      Width = 121
      Height = 23
      TabOrder = 5
      Text = 'AUT0801KIT'
    end
  end
  object pgcTabs: TcxPageControl
    AlignWithMargins = True
    Left = 3
    Top = 124
    Width = 1110
    Height = 612
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tabATP
    Properties.CustomButtons.Buttons = <>
    Properties.TabHeight = 28
    OnChange = pgcTabsChange
    ExplicitHeight = 422
    ClientRectBottom = 608
    ClientRectLeft = 4
    ClientRectRight = 1106
    ClientRectTop = 34
    object tabDisponibilidad: TcxTabSheet
      Caption = 'Disponibilidad fabricaci'#243'n'
      ExplicitHeight = 384
      object pnlDispTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 70
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          70)
        object lblDispCantidad: TLabel
          Left = 12
          Top = 12
          Width = 94
          Height = 15
          Caption = 'Cantidad fabricar:'
        end
        object lblDispFecha: TLabel
          Left = 240
          Top = 12
          Width = 80
          Height = 15
          Caption = 'Fecha objetivo:'
        end
        object lblDispLeyenda: TLabel
          Left = 12
          Top = 48
          Width = 800
          Height = 15
          AutoSize = False
          Caption = 
            'Tipo: P=Producto fabricado  S=Semielaborado  M=Materia prima  | ' +
            ' Estado: OK / FALTA / CRITICO'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object seDispCantidad: TcxSpinEdit
          Left = 110
          Top = 9
          Properties.MinValue = 1.000000000000000000
          Properties.ValueType = vtFloat
          TabOrder = 0
          Value = 1.000000000000000000
          Width = 110
        end
        object dtDispFecha: TDateTimePicker
          Left = 335
          Top = 9
          Width = 130
          Height = 23
          Date = 44562.000000000000000000
          Time = 44562.000000000000000000
          TabOrder = 1
        end
        object btnRecargarDisp: TButton
          Left = 988
          Top = 6
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Calcular'
          TabOrder = 2
          OnClick = btnRecargarDispClick
        end
      end
      object tlDisp: TcxTreeList
        AlignWithMargins = True
        Left = 3
        Top = 73
        Width = 1096
        Height = 457
        Align = alClient
        Bands = <
          item
          end>
        Navigator.Buttons.CustomButtons = <>
        OptionsBehavior.CellHints = True
        OptionsData.Editing = False
        OptionsView.GridLines = tlglBoth
        ScrollbarAnnotations.CustomAnnotations = <>
        TabOrder = 1
        OnCustomDrawDataCell = tlDispCustomDrawDataCell
        ExplicitHeight = 308
        object colDispArticulo: TcxTreeListColumn
          Caption.Text = 'Art'#237'culo'
          Width = 180
          Position.ColIndex = 0
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispDescripcion: TcxTreeListColumn
          Caption.Text = 'Descripci'#243'n'
          Width = 240
          Position.ColIndex = 1
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispTipo: TcxTreeListColumn
          Caption.Text = 'Tipo'
          Width = 50
          Position.ColIndex = 2
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispNecesario: TcxTreeListColumn
          Caption.Text = 'Necesario'
          Width = 90
          Position.ColIndex = 3
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispStockActual: TcxTreeListColumn
          Caption.Text = 'Stock actual'
          Width = 90
          Position.ColIndex = 4
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispStockProy: TcxTreeListColumn
          Caption.Text = 'Stock proyectado'
          Width = 110
          Position.ColIndex = 5
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispFaltaActual: TcxTreeListColumn
          Caption.Text = 'Falta hoy'
          Width = 80
          Position.ColIndex = 6
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispFaltaProy: TcxTreeListColumn
          Caption.Text = 'Falta proyect.'
          Width = 90
          Position.ColIndex = 7
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
        object colDispEstado: TcxTreeListColumn
          Caption.Text = 'Estado'
          Width = 70
          Position.ColIndex = 8
          Position.RowIndex = 0
          Position.BandIndex = 0
          Summary.FooterSummaryItems = <>
          Summary.GroupFooterSummaryItems = <>
        end
      end
      object Panel1: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 2
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblDispVeredicto: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 1096
          Height = 35
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 62
          ExplicitWidth = 600
          ExplicitHeight = 25
        end
      end
    end
    object tabDondeUsa: TcxTabSheet
      Caption = 'D'#243'nde se usa'
      ExplicitHeight = 384
      object pnlDondeUsaTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          40)
        object btnRecargarDondeUsa: TButton
          Left = 969
          Top = 7
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Recargar'
          TabOrder = 0
          OnClick = btnRecargarDondeUsaClick
        end
      end
      object grdDondeUsa: TcxGrid
        AlignWithMargins = True
        Left = 3
        Top = 43
        Width = 1096
        Height = 487
        Align = alClient
        TabOrder = 1
        ExplicitHeight = 338
        object grdDondeUsaView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.DataSource = dsDondeUsa
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdDondeUsaLevel: TcxGridLevel
          GridView = grdDondeUsaView
        end
      end
      object Panel2: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 2
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblDondeUsaResumen: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 3
          Width = 1091
          Height = 35
          Margins.Left = 8
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 20
          ExplicitTop = 20
          ExplicitWidth = 600
          ExplicitHeight = 17
        end
      end
    end
    object tabHistorico: TcxTabSheet
      Caption = 'Hist'#243'rico'
      ExplicitHeight = 384
      object pbHistorico: TPaintBox
        AlignWithMargins = True
        Left = 3
        Top = 43
        Width = 1096
        Height = 487
        Align = alClient
        OnPaint = pbHistoricoPaint
        ExplicitLeft = 0
        ExplicitTop = 40
        ExplicitHeight = 506
      end
      object pnlHistTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          40)
        object lblHistMeses: TLabel
          Left = 12
          Top = 12
          Width = 36
          Height = 15
          Caption = 'Meses:'
        end
        object seHistMeses: TcxSpinEdit
          Left = 60
          Top = 9
          Properties.MaxValue = 60.000000000000000000
          Properties.MinValue = 3.000000000000000000
          TabOrder = 0
          Value = 12
          Width = 80
        end
        object btnRecargarHist: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Recargar'
          TabOrder = 1
          OnClick = btnRecargarHistClick
        end
      end
      object Panel3: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 1
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblHistResumen: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 3
          Width = 1086
          Height = 35
          Margins.Left = 8
          Margins.Right = 8
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 200
          ExplicitTop = 12
          ExplicitWidth = 700
          ExplicitHeight = 17
        end
      end
    end
    object tabOFs: TcxTabSheet
      Caption = 'OFs activas'
      ExplicitHeight = 384
      object pnlOFsTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          40)
        object btnRecargarOFs: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Recargar'
          TabOrder = 0
          OnClick = btnRecargarOFsClick
        end
      end
      object grdOFs: TcxGrid
        AlignWithMargins = True
        Left = 3
        Top = 43
        Width = 1096
        Height = 487
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 40
        ExplicitWidth = 1102
        ExplicitHeight = 344
        object grdOFsView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.DataSource = dsOFs
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdOFsLevel: TcxGridLevel
          GridView = grdOFsView
        end
      end
      object Panel4: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 2
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblOFsResumen: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 3
          Width = 1086
          Height = 35
          Margins.Left = 8
          Margins.Right = 8
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 20
          ExplicitTop = 20
          ExplicitWidth = 700
          ExplicitHeight = 17
        end
      end
    end
    object tabProveedores: TcxTabSheet
      Caption = 'Proveedores'
      ExplicitHeight = 384
      object pnlProvTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          40)
        object lblProvMeses: TLabel
          Left = 12
          Top = 12
          Width = 114
          Height = 15
          Caption = 'Meses atr'#225's (0=todo):'
        end
        object seProvMeses: TcxSpinEdit
          Left = 134
          Top = 9
          Properties.AssignedValues.MinValue = True
          Properties.MaxValue = 120.000000000000000000
          TabOrder = 0
          Value = 24
          Width = 80
        end
        object btnRecargarProv: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Recargar'
          TabOrder = 1
          OnClick = btnRecargarProvClick
        end
      end
      object grdProv: TcxGrid
        AlignWithMargins = True
        Left = 3
        Top = 43
        Width = 1096
        Height = 487
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 40
        ExplicitWidth = 1102
        ExplicitHeight = 344
        object grdProvView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.DataSource = dsProv
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdProvLevel: TcxGridLevel
          GridView = grdProvView
        end
      end
      object Panel5: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 2
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblProvResumen: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 3
          Width = 1086
          Height = 35
          Margins.Left = 8
          Margins.Right = 8
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 228
          ExplicitTop = 20
          ExplicitWidth = 700
          ExplicitHeight = 17
        end
      end
    end
    object tabClientes: TcxTabSheet
      Caption = 'Clientes'
      ExplicitHeight = 384
      object pnlCliTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          40)
        object lblCliMeses: TLabel
          Left = 12
          Top = 12
          Width = 114
          Height = 15
          Caption = 'Meses atr'#225's (0=todo):'
        end
        object seCliMeses: TcxSpinEdit
          Left = 135
          Top = 9
          Properties.AssignedValues.MinValue = True
          Properties.MaxValue = 120.000000000000000000
          TabOrder = 0
          Value = 24
          Width = 80
        end
        object btnRecargarCli: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Recargar'
          TabOrder = 1
          OnClick = btnRecargarCliClick
        end
      end
      object grdCli: TcxGrid
        AlignWithMargins = True
        Left = 3
        Top = 43
        Width = 1096
        Height = 487
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 40
        ExplicitWidth = 1102
        ExplicitHeight = 344
        object grdCliView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.DataSource = dsCli
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdCliLevel: TcxGridLevel
          GridView = grdCliView
        end
      end
      object Panel6: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 2
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblCliResumen: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 3
          Width = 1086
          Height = 35
          Margins.Left = 8
          Margins.Right = 8
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 220
          ExplicitTop = 12
          ExplicitWidth = 700
          ExplicitHeight = 17
        end
      end
    end
    object tabMovimientos: TcxTabSheet
      Caption = 'Movimientos futuros'
      ExplicitHeight = 384
      object pnlMovsFutTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          40)
        object lblMovsFutDesde: TLabel
          Left = 12
          Top = 12
          Width = 35
          Height = 15
          Caption = 'Desde:'
        end
        object lblMovsFutHasta: TLabel
          Left = 195
          Top = 12
          Width = 33
          Height = 15
          Caption = 'Hasta:'
        end
        object dtMovsFutDesde: TDateTimePicker
          Left = 60
          Top = 9
          Width = 120
          Height = 23
          Date = 44562.000000000000000000
          Time = 44562.000000000000000000
          TabOrder = 0
        end
        object dtMovsFutHasta: TDateTimePicker
          Left = 240
          Top = 9
          Width = 120
          Height = 23
          Date = 44562.000000000000000000
          Time = 44562.000000000000000000
          TabOrder = 1
        end
        object chkMovFutCompras: TCheckBox
          Left = 370
          Top = 12
          Width = 75
          Height = 17
          Caption = 'Compras'
          Checked = True
          State = cbChecked
          TabOrder = 2
          OnClick = MovFutTipoChange
        end
        object chkMovFutVentas: TCheckBox
          Left = 498
          Top = 12
          Width = 70
          Height = 17
          Caption = 'Ventas'
          Checked = True
          State = cbChecked
          TabOrder = 3
          OnClick = MovFutTipoChange
        end
        object chkMovFutOFs: TCheckBox
          Left = 448
          Top = 12
          Width = 44
          Height = 17
          Caption = 'OFs'
          Checked = True
          State = cbChecked
          TabOrder = 4
          OnClick = MovFutTipoChange
        end
        object btnRecargarMovsFut: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Recargar'
          TabOrder = 5
          OnClick = btnRecargarMovsFutClick
        end
      end
      object grdMovsFut: TcxGrid
        AlignWithMargins = True
        Left = 3
        Top = 43
        Width = 1096
        Height = 487
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 40
        ExplicitWidth = 1102
        ExplicitHeight = 344
        object grdMovsFutView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          OnCustomDrawCell = grdMovsFutViewCustomDrawCell
          DataController.DataSource = dsMovsFut
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdMovsFutLevel: TcxGridLevel
          GridView = grdMovsFutView
        end
      end
      object Panel7: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 2
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblMovsFutResumen: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 3
          Width = 1086
          Height = 35
          Margins.Left = 8
          Margins.Right = 8
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 480
          ExplicitTop = 12
          ExplicitWidth = 480
          ExplicitHeight = 17
        end
      end
    end
    object tabPartidas: TcxTabSheet
      Caption = 'Stock por partida / lote'
      ExplicitHeight = 384
      object pnlPartidasTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          1102
          40)
        object btnRecargarPartidas: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Anchors = [akTop, akRight]
          Caption = 'Recargar'
          TabOrder = 0
          OnClick = btnRecargarPartidasClick
        end
        object chkSoloConSaldo: TCheckBox
          Left = 640
          Top = 12
          Width = 200
          Height = 17
          Caption = 'Solo con saldo distinto de 0'
          Checked = True
          State = cbChecked
          TabOrder = 1
          OnClick = chkSoloConSaldoClick
        end
      end
      object grdPartidas: TcxGrid
        AlignWithMargins = True
        Left = 3
        Top = 43
        Width = 1096
        Height = 487
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 40
        ExplicitWidth = 1102
        ExplicitHeight = 344
        object grdPartidasView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          OnCustomDrawCell = grdPartidasViewCustomDrawCell
          DataController.DataSource = dsPartidas
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.Footer = True
        end
        object grdPartidasLevel: TcxGridLevel
          GridView = grdPartidasView
        end
      end
      object Panel8: TPanel
        Left = 0
        Top = 533
        Width = 1102
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 2
        ExplicitLeft = 456
        ExplicitTop = 264
        ExplicitWidth = 185
        object lblPartidasResumen: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 3
          Width = 1086
          Height = 35
          Margins.Left = 8
          Margins.Right = 8
          Align = alClient
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 20
          ExplicitTop = 20
          ExplicitWidth = 600
          ExplicitHeight = 17
        end
      end
    end
    object tabATP: TcxTabSheet
      Caption = 'Projected Stock (ATP)'
      ExplicitHeight = 384
      object pnlResumen: TPanel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1096
        Height = 90
        Align = alTop
        BevelOuter = bvLowered
        Color = clInfoBk
        ParentBackground = False
        TabOrder = 0
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 1102
        object lblTitResumen: TLabel
          Left = 12
          Top = 6
          Width = 55
          Height = 15
          Caption = 'Resumen:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblStockInicial: TLabel
          Left = 12
          Top = 28
          Width = 66
          Height = 15
          Caption = 'Stock inicial:'
        end
        object lblValStockInicial: TLabel
          Left = 12
          Top = 46
          Width = 120
          Height = 18
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblTotalEntradas: TLabel
          Left = 160
          Top = 28
          Width = 48
          Height = 15
          Caption = 'Entradas:'
        end
        object lblValTotalEntradas: TLabel
          Left = 160
          Top = 46
          Width = 130
          Height = 18
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGreen
          Font.Height = -14
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblTotalSalidas: TLabel
          Left = 310
          Top = 28
          Width = 39
          Height = 15
          Caption = 'Salidas:'
        end
        object lblValTotalSalidas: TLabel
          Left = 310
          Top = 46
          Width = 130
          Height = 18
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -14
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblStockFinal: TLabel
          Left = 470
          Top = 28
          Width = 99
          Height = 15
          Caption = 'Stock final a fecha:'
        end
        object lblValStockFinal: TLabel
          Left = 470
          Top = 46
          Width = 140
          Height = 22
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -18
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblStockMinimo: TLabel
          Left = 640
          Top = 28
          Width = 97
          Height = 15
          Caption = 'Stock m'#237'nimo art.:'
        end
        object lblValStockMinimo: TLabel
          Left = 640
          Top = 46
          Width = 130
          Height = 18
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object pnlRecomendacion: TPanel
        AlignWithMargins = True
        Left = 3
        Top = 99
        Width = 1096
        Height = 44
        Align = alTop
        BevelOuter = bvLowered
        Color = clCream
        ParentBackground = False
        TabOrder = 2
        Visible = False
        ExplicitLeft = 0
        ExplicitTop = 90
        ExplicitWidth = 1102
        DesignSize = (
          1096
          44)
        object lblRecomendacion: TLabel
          Left = 12
          Top = 12
          Width = 800
          Height = 20
          AutoSize = False
          Caption = 'Recomendaci'#243'n MRP'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnAccionMrp: TButton
          Left = 940
          Top = 8
          Width = 144
          Height = 28
          Anchors = [akTop, akRight]
          Caption = 'Fabricar '#8594' Gantt'
          TabOrder = 0
          Visible = False
          OnClick = btnAccionMrpClick
          ExplicitLeft = 946
        end
      end
      object pnlMovsContainer: TPanel
        Left = 0
        Top = 146
        Width = 1102
        Height = 428
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitTop = 134
        ExplicitHeight = 250
        object grdMovs: TcxGrid
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 1096
          Height = 381
          Align = alClient
          TabOrder = 0
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 1102
          ExplicitHeight = 250
          object grdMovsView: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            OnCustomDrawCell = grdMovsViewCustomDrawCell
            DataController.DataSource = dsMovs
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.CellSelect = False
          end
          object grdMovsLevel: TcxGridLevel
            GridView = grdMovsView
          end
        end
        object Panel9: TPanel
          Left = 0
          Top = 387
          Width = 1102
          Height = 41
          Align = alBottom
          BevelOuter = bvNone
          Color = 15921906
          ParentBackground = False
          TabOrder = 1
          ExplicitLeft = 456
          ExplicitTop = 264
          ExplicitWidth = 185
          object lblAviso: TLabel
            AlignWithMargins = True
            Left = 8
            Top = 3
            Width = 1086
            Height = 35
            Margins.Left = 8
            Margins.Right = 8
            Align = alClient
            AutoSize = False
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clRed
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            Visible = False
            ExplicitLeft = 800
            ExplicitTop = 23
            ExplicitWidth = 280
            ExplicitHeight = 18
          end
        end
      end
    end
    object cxTabSheet1: TcxTabSheet
      Caption = 'Log'
      ImageIndex = 9
      ExplicitHeight = 384
      object mmoLog: TMemo
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1096
        Height = 568
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitLeft = 40
        ExplicitTop = 6
        ExplicitWidth = 1116
        ExplicitHeight = 140
      end
    end
  end
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 1116
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3748653
    ParentBackground = False
    TabOrder = 2
    object lblTitulo: TLabel
      Left = 69
      Top = 5
      Width = 51
      Height = 32
      Caption = 'MRP'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 69
      Top = 39
      Width = 226
      Height = 15
      Caption = 'Planificaci'#243'n de Necesidades de Materiales'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnFocus: TButton
      Left = 164
      Top = 8
      Width = 75
      Height = 25
      Caption = 'btnFocus'
      TabOrder = 0
    end
    object imgSection: TcxImage
      AlignWithMargins = True
      Left = 3
      Top = 6
      Margins.Top = 6
      Margins.Right = 5
      Margins.Bottom = 12
      Align = alLeft
      Picture.Data = {
        0D546478536D617274496D6167653C3F786D6C2076657273696F6E3D22312E30
        2220656E636F64696E673D225554462D38223F3E0D0A3C737667207665727369
        6F6E3D22312E31222069643D224C617965725F312220786D6C6E733D22687474
        703A2F2F7777772E77332E6F72672F323030302F7376672220786D6C6E733A78
        6C696E6B3D22687474703A2F2F7777772E77332E6F72672F313939392F786C69
        6E6B2220783D223070782220793D22307078222076696577426F783D22302030
        20333220333222207374796C653D22656E61626C652D6261636B67726F756E64
        3A6E6577203020302033322033323B2220786D6C3A73706163653D2270726573
        65727665223E262331333B262331303B3C7374796C6520747970653D22746578
        742F6373732220786D6C3A73706163653D227072657365727665223E2E59656C
        6C6F777B66696C6C3A234646423131353B7D262331333B262331303B2623393B
        2E5265647B66696C6C3A234431314331433B7D262331333B262331303B262339
        3B2E426C61636B7B66696C6C3A233732373237323B7D262331333B262331303B
        2623393B2E477265656E7B66696C6C3A233033394332333B7D262331333B2623
        31303B2623393B2E426C75657B66696C6C3A233131373744373B7D3C2F737479
        6C653E0D0A3C672069643D2253686F7070696E6743617274223E0D0A09093C63
        6972636C6520636C6173733D22426C61636B222063783D223133222063793D22
        32372220723D2233222F3E0D0A09093C7061746820636C6173733D22426C6163
        6B2220643D224D31362E332C313868372E3963302E342C302C302E372D302E32
        2C302E392D302E356C342E382D384333302E332C382E382C32392E382C382C32
        392C384831302E344C362E382C3268304832763268332E376C372E382C31332E
        324C31302E362C323020202623393B2623393B6C2D302E342C302E3443392E37
        2C32312C31302E312C32322C31312C323268302E35483238762D324831332E35
        6C322D324831362E337A222F3E0D0A09093C636972636C6520636C6173733D22
        426C61636B222063783D223235222063793D2232372220723D2233222F3E0D0A
        093C2F673E0D0A3C2F7376673E0D0A}
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Properties.ShowFocusRect = False
      Style.BorderStyle = ebsNone
      TabOrder = 1
      Transparent = True
      Height = 52
      Width = 56
    end
    object pnlKPIs: TPanel
      AlignWithMargins = True
      Left = 341
      Top = 3
      Width = 772
      Height = 64
      Align = alRight
      BevelOuter = bvNone
      Color = 3748653
      ParentBackground = False
      TabOrder = 2
      object pnlKPI2: TPanel
        AlignWithMargins = True
        Left = 145
        Top = 0
        Width = 120
        Height = 64
        Margins.Top = 0
        Margins.Bottom = 0
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        ParentBackground = False
        TabOrder = 0
        object lblKPI2Cap: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 3
          Width = 110
          Height = 15
          Margins.Left = 5
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = 'Disponible'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 12
          ExplicitTop = 10
          ExplicitWidth = 151
        end
        object lblKPI2Val: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 18
          Width = 110
          Height = 24
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 3
          ExplicitTop = 21
          ExplicitWidth = 134
        end
        object lblKPI2Sub: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 47
          Width = 110
          Height = 14
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Align = alBottom
          AutoSize = False
          Caption = 'saldo - reservado'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ExplicitLeft = 12
          ExplicitTop = 60
          ExplicitWidth = 151
        end
      end
      object pnlKPI3: TPanel
        AlignWithMargins = True
        Left = 271
        Top = 0
        Width = 120
        Height = 64
        Margins.Top = 0
        Margins.Bottom = 0
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        ParentBackground = False
        TabOrder = 1
        object lblKPI3Cap: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 3
          Width = 110
          Height = 15
          Margins.Left = 5
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = 'D'#237'as cobertura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 12
          ExplicitTop = 10
          ExplicitWidth = 151
        end
        object lblKPI3Val: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 18
          Width = 110
          Height = 24
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 3
          ExplicitTop = 21
          ExplicitWidth = 134
        end
        object lblKPI3Sub: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 47
          Width = 110
          Height = 14
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Align = alBottom
          AutoSize = False
          Caption = 'al ritmo actual'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ExplicitLeft = 12
          ExplicitTop = 60
          ExplicitWidth = 151
        end
      end
      object pnlKPI4: TPanel
        AlignWithMargins = True
        Left = 397
        Top = 0
        Width = 120
        Height = 64
        Margins.Top = 0
        Margins.Bottom = 0
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        ParentBackground = False
        TabOrder = 2
        object lblKPI4Cap: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 3
          Width = 110
          Height = 15
          Margins.Left = 5
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = 'Pendiente recibir'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 12
          ExplicitTop = 10
          ExplicitWidth = 151
        end
        object lblKPI4Val: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 18
          Width = 110
          Height = 24
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 3
          ExplicitTop = 21
          ExplicitWidth = 134
        end
        object lblKPI4Sub: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 47
          Width = 110
          Height = 14
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Align = alBottom
          AutoSize = False
          Caption = 'pedidos compra'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ExplicitLeft = 12
          ExplicitTop = 60
          ExplicitWidth = 151
        end
      end
      object pnlKPI5: TPanel
        AlignWithMargins = True
        Left = 523
        Top = 0
        Width = 120
        Height = 64
        Margins.Top = 0
        Margins.Bottom = 0
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        ParentBackground = False
        TabOrder = 3
        object lblKPI5Cap: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 3
          Width = 110
          Height = 15
          Margins.Left = 5
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = 'Pendiente servir'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 12
          ExplicitTop = 10
          ExplicitWidth = 151
        end
        object lblKPI5Val: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 18
          Width = 110
          Height = 24
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 3
          ExplicitTop = 21
          ExplicitWidth = 134
        end
        object lblKPI5Sub: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 47
          Width = 110
          Height = 14
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Align = alBottom
          AutoSize = False
          Caption = 'pedidos venta'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ExplicitLeft = 12
          ExplicitTop = 60
          ExplicitWidth = 151
        end
      end
      object pnlKPI6: TPanel
        AlignWithMargins = True
        Left = 649
        Top = 0
        Width = 120
        Height = 64
        Margins.Top = 0
        Margins.Bottom = 0
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        ParentBackground = False
        TabOrder = 4
        object lblKPI6Cap: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 3
          Width = 110
          Height = 15
          Margins.Left = 5
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = 'Clasificaci'#243'n ABC'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 12
          ExplicitTop = 10
          ExplicitWidth = 151
        end
        object lblKPI6Val: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 18
          Width = 110
          Height = 24
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 3
          ExplicitTop = 21
          ExplicitWidth = 134
        end
        object lblKPI6Sub: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 47
          Width = 110
          Height = 14
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Align = alBottom
          AutoSize = False
          Caption = 'por importe consumo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ExplicitLeft = 12
          ExplicitTop = 60
          ExplicitWidth = 151
        end
      end
      object pnlKPI1: TPanel
        AlignWithMargins = True
        Left = 19
        Top = 0
        Width = 120
        Height = 64
        Margins.Left = 1
        Margins.Top = 0
        Margins.Bottom = 0
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 8220514
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 5
        object lblKPI1Cap: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 3
          Width = 110
          Height = 16
          Cursor = crHandPoint
          Margins.Left = 5
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = 'Stock actual'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
          ExplicitLeft = 0
          ExplicitTop = 8
          ExplicitWidth = 80
        end
        object lblKPI1Sub: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 47
          Width = 110
          Height = 14
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Align = alBottom
          AutoSize = False
          Caption = 'unidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ExplicitLeft = -5
          ExplicitTop = 46
          ExplicitWidth = 151
        end
        object lblKPI1Val: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 19
          Width = 110
          Height = 24
          Margins.Left = 5
          Margins.Top = 0
          Margins.Right = 5
          Margins.Bottom = 0
          Align = alTop
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -20
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          ExplicitLeft = 3
          ExplicitWidth = 140
        end
      end
    end
  end
  object cdsDondeUsa: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 544
    Top = 200
  end
  object dsDondeUsa: TDataSource
    DataSet = cdsDondeUsa
    Left = 928
    Top = 200
  end
  object cdsOFs: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 360
    Top = 200
  end
  object dsOFs: TDataSource
    DataSet = cdsOFs
    Left = 864
    Top = 200
  end
  object cdsProv: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 616
    Top = 200
  end
  object dsProv: TDataSource
    DataSet = cdsProv
    Left = 816
    Top = 208
  end
  object cdsCli: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 664
    Top = 200
  end
  object dsCli: TDataSource
    DataSet = cdsCli
    Left = 752
    Top = 208
  end
  object cdsMovs: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 400
    Top = 230
  end
  object dsMovs: TDataSource
    DataSet = cdsMovs
    Left = 456
    Top = 230
  end
  object cdsPartidas: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 400
    Top = 290
  end
  object cdsMovsFut: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 400
    Top = 350
  end
  object dsMovsFut: TDataSource
    DataSet = cdsMovsFut
    Left = 456
    Top = 350
  end
  object dsPartidas: TDataSource
    DataSet = cdsPartidas
    Left = 456
    Top = 290
  end
end
