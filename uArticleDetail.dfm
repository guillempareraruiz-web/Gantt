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
  object splitLog: TSplitter
    Left = 0
    Top = 549
    Width = 1116
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    Visible = False
    ExplicitTop = 550
    ExplicitWidth = 100
  end
  object pnlTop: TPanel
    Left = 0
    Top = 70
    Width = 1116
    Height = 51
    Align = alTop
    BevelOuter = bvNone
    Color = 9404016
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1116
      51)
    object lblArticulo: TLabel
      Left = 12
      Top = 8
      Width = 45
      Height = 15
      Caption = 'Art'#237'culo:'
    end
    object lblDescripcion: TLabel
      Left = 199
      Top = 6
      Width = 67
      Height = 15
      AutoSize = False
      Caption = 'Desc'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblAlmacenes: TLabel
      Left = 314
      Top = 6
      Width = 61
      Height = 15
      Caption = 'Almacenes:'
    end
    object lblFecha: TLabel
      Left = 748
      Top = 6
      Width = 96
      Height = 15
      Caption = 'Fecha proyecci'#243'n:'
    end
    object edArticulo: TEdit
      Left = 12
      Top = 22
      Width = 180
      Height = 23
      TabOrder = 0
    end
    object btnBuscarArticulo: TButton
      Left = 197
      Top = 21
      Width = 30
      Height = 25
      Caption = '...'
      TabOrder = 1
      OnClick = btnBuscarArticuloClick
    end
    object ccbAlmacenes: TcxCheckComboBox
      Left = 314
      Top = 22
      Properties.Items = <>
      TabOrder = 2
      Width = 400
    end
    object dtFecha: TDateTimePicker
      Left = 748
      Top = 22
      Width = 130
      Height = 23
      Date = 44562.000000000000000000
      Time = 44562.000000000000000000
      TabOrder = 3
    end
    object btnCalcular: TButton
      Left = 990
      Top = 9
      Width = 116
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Calcular'
      Default = True
      TabOrder = 4
      OnClick = btnCalcularClick
    end
    object btnToggleLog: TButton
      Left = 900
      Top = 6
      Width = 84
      Height = 25
      Caption = 'Mostrar log'
      TabOrder = 5
      OnClick = btnToggleLogClick
    end
    object Edit1: TEdit
      Left = 72
      Top = 0
      Width = 121
      Height = 23
      TabOrder = 6
      Text = 'AUT0801KIT'
    end
  end
  object pgcTabs: TcxPageControl
    AlignWithMargins = True
    Left = 3
    Top = 124
    Width = 1110
    Height = 422
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tabOFs
    Properties.CustomButtons.Buttons = <>
    Properties.TabHeight = 28
    OnChange = pgcTabsChange
    ExplicitLeft = 0
    ExplicitTop = 121
    ExplicitWidth = 1116
    ExplicitHeight = 428
    ClientRectBottom = 418
    ClientRectLeft = 4
    ClientRectRight = 1106
    ClientRectTop = 34
    object tabDisponibilidad: TcxTabSheet
      Caption = 'Disponibilidad fabricaci'#243'n'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlDispTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 70
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
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
        object lblDispVeredicto: TLabel
          Left = 480
          Top = 8
          Width = 600
          Height = 25
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
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
          Left = 970
          Top = 38
          Width = 110
          Height = 26
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
        Height = 308
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
        ExplicitLeft = 0
        ExplicitTop = 70
        ExplicitWidth = 1102
        ExplicitHeight = 314
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
    end
    object tabDondeUsa: TcxTabSheet
      Caption = 'D'#243'nde se usa'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlDondeUsaTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblDondeUsaResumen: TLabel
          Left = 12
          Top = 12
          Width = 600
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnRecargarDondeUsa: TButton
          Left = 983
          Top = 3
          Width = 110
          Height = 26
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
        Height = 338
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 40
        ExplicitWidth = 1102
        ExplicitHeight = 344
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
    end
    object tabHistorico: TcxTabSheet
      Caption = 'Hist'#243'rico'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pbHistorico: TPaintBox
        Left = 0
        Top = 40
        Width = 1102
        Height = 344
        Align = alClient
        OnPaint = pbHistoricoPaint
        ExplicitWidth = 1096
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
        object lblHistMeses: TLabel
          Left = 12
          Top = 12
          Width = 36
          Height = 15
          Caption = 'Meses:'
        end
        object lblHistResumen: TLabel
          Left = 200
          Top = 12
          Width = 700
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
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
          Caption = 'Recargar'
          TabOrder = 1
          OnClick = btnRecargarHistClick
        end
      end
    end
    object tabOFs: TcxTabSheet
      Caption = 'OFs activas'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlOFsTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblOFsResumen: TLabel
          Left = 12
          Top = 12
          Width = 700
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnRecargarOFs: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Caption = 'Recargar'
          TabOrder = 0
          OnClick = btnRecargarOFsClick
        end
      end
      object grdOFs: TcxGrid
        Left = 0
        Top = 40
        Width = 1102
        Height = 344
        Align = alClient
        TabOrder = 1
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
    end
    object tabProveedores: TcxTabSheet
      Caption = 'Proveedores'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlProvTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblProvMeses: TLabel
          Left = 12
          Top = 12
          Width = 114
          Height = 15
          Caption = 'Meses atr'#225's (0=todo):'
        end
        object lblProvResumen: TLabel
          Left = 220
          Top = 12
          Width = 700
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
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
          Caption = 'Recargar'
          TabOrder = 1
          OnClick = btnRecargarProvClick
        end
      end
      object grdProv: TcxGrid
        Left = 0
        Top = 40
        Width = 1102
        Height = 344
        Align = alClient
        TabOrder = 1
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
    end
    object tabClientes: TcxTabSheet
      Caption = 'Clientes'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlCliTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblCliMeses: TLabel
          Left = 12
          Top = 12
          Width = 114
          Height = 15
          Caption = 'Meses atr'#225's (0=todo):'
        end
        object lblCliResumen: TLabel
          Left = 220
          Top = 12
          Width = 700
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
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
          Caption = 'Recargar'
          TabOrder = 1
          OnClick = btnRecargarCliClick
        end
      end
      object grdCli: TcxGrid
        Left = 0
        Top = 40
        Width = 1102
        Height = 344
        Align = alClient
        TabOrder = 1
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
    end
    object tabMovimientos: TcxTabSheet
      Caption = 'Movimientos futuros'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlMovsFutTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
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
        object lblMovsFutResumen: TLabel
          Left = 480
          Top = 12
          Width = 480
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
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
          Left = 370
          Top = 28
          Width = 70
          Height = 17
          Caption = 'Ventas'
          Checked = True
          State = cbChecked
          TabOrder = 3
          OnClick = MovFutTipoChange
        end
        object chkMovFutOFs: TCheckBox
          Left = 440
          Top = 12
          Width = 60
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
          Caption = 'Recargar'
          TabOrder = 5
          OnClick = btnRecargarMovsFutClick
        end
      end
      object grdMovsFut: TcxGrid
        Left = 0
        Top = 40
        Width = 1102
        Height = 344
        Align = alClient
        TabOrder = 1
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
    end
    object tabPartidas: TcxTabSheet
      Caption = 'Stock por partida / lote'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlPartidasTop: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblPartidasResumen: TLabel
          Left = 12
          Top = 12
          Width = 600
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnRecargarPartidas: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
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
        Left = 0
        Top = 40
        Width = 1102
        Height = 344
        Align = alClient
        TabOrder = 1
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
    end
    object tabATP: TcxTabSheet
      Caption = 'Projected Stock (ATP)'
      ExplicitTop = 26
      ExplicitWidth = 1108
      ExplicitHeight = 398
      object pnlResumen: TPanel
        Left = 0
        Top = 0
        Width = 1102
        Height = 90
        Align = alTop
        BevelOuter = bvLowered
        Color = clInfoBk
        ParentBackground = False
        TabOrder = 0
        ExplicitWidth = 1108
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
        object lblAviso: TLabel
          Left = 800
          Top = 46
          Width = 280
          Height = 18
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Visible = False
        end
      end
      object pnlRecomendacion: TPanel
        Left = 0
        Top = 90
        Width = 1102
        Height = 44
        Align = alTop
        BevelOuter = bvLowered
        Color = clCream
        ParentBackground = False
        TabOrder = 2
        Visible = False
        ExplicitWidth = 1108
        DesignSize = (
          1102
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
          Left = 946
          Top = 8
          Width = 144
          Height = 28
          Anchors = [akTop, akRight]
          Caption = 'Fabricar '#8594' Gantt'
          TabOrder = 0
          Visible = False
          OnClick = btnAccionMrpClick
          ExplicitLeft = 952
        end
      end
      object pnlMovsContainer: TPanel
        Left = 0
        Top = 134
        Width = 1102
        Height = 250
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitWidth = 1108
        ExplicitHeight = 264
        object grdMovs: TcxGrid
          Left = 0
          Top = 0
          Width = 1102
          Height = 250
          Align = alClient
          TabOrder = 0
          ExplicitWidth = 1108
          ExplicitHeight = 264
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
      end
    end
  end
  object pnlLog: TPanel
    Left = 0
    Top = 554
    Width = 1116
    Height = 140
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    Visible = False
    object mmoLog: TMemo
      Left = 0
      Top = 0
      Width = 1116
      Height = 140
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
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 694
    Width = 1116
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
  end
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 1116
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 6313290
    ParentBackground = False
    TabOrder = 4
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
        2220656E636F64696E673D225554462D38223F3E0D0A3C737667207669657742
        6F783D223020302032342032342220786D6C6E733D22687474703A2F2F777777
        2E77332E6F72672F323030302F737667223E0D0A093C706174682066696C6C3D
        2223464646464646222066696C6C2D6F7061636974793D22302E352220643D22
        4D313220335637483356334831325A4D31362031375632314833563137483136
        5A4D323220313056313448335631304832325A222F3E0D0A3C2F7376673E0D0A}
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
      Color = 6313290
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
