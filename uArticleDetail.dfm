object frmArticleDetail: TfrmArticleDetail
  Left = 0
  Top = 0
  Caption = 'Detalle de art'#237'culo'
  ClientHeight = 700
  ClientWidth = 1100
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
    Top = 0
    Width = 1100
    Height = 170
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblArticulo: TLabel
      Left = 12
      Top = 10
      Width = 49
      Height = 15
      Caption = 'Art'#237'culo:'
    end
    object lblDescripcion: TLabel
      Left = 290
      Top = 12
      Width = 500
      Height = 15
      AutoSize = False
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblAlmacenes: TLabel
      Left = 12
      Top = 46
      Width = 62
      Height = 15
      Caption = 'Almacenes:'
    end
    object lblFecha: TLabel
      Left = 500
      Top = 46
      Width = 96
      Height = 15
      Caption = 'Fecha proyecci'#243'n:'
    end
    object edArticulo: TEdit
      Left = 70
      Top = 8
      Width = 180
      Height = 23
      TabOrder = 0
    end
    object btnBuscarArticulo: TButton
      Left = 254
      Top = 7
      Width = 30
      Height = 25
      Caption = '...'
      TabOrder = 1
      OnClick = btnBuscarArticuloClick
    end
    object ccbAlmacenes: TcxCheckComboBox
      Left = 80
      Top = 42
      Width = 400
      TabOrder = 2
    end
    object dtFecha: TDateTimePicker
      Left = 600
      Top = 42
      Width = 130
      Height = 23
      Date = 44562.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 3
    end
    object btnCalcular: TButton
      Left = 750
      Top = 41
      Width = 130
      Height = 26
      Caption = 'Calcular'
      Default = True
      TabOrder = 4
      OnClick = btnCalcularClick
    end
    object pnlKPIs: TPanel
      Left = 0
      Top = 78
      Width = 1100
      Height = 92
      Align = alBottom
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 5
      object pnlKPI1: TPanel
        Left = 12
        Top = 6
        Width = 175
        Height = 80
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 0
        object lblKPI1Cap: TLabel
          Left = 12
          Top = 10
          Width = 151
          Height = 15
          AutoSize = False
          Caption = 'Stock actual'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI1Val: TLabel
          Left = 12
          Top = 28
          Width = 151
          Height = 32
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -24
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI1Sub: TLabel
          Left = 12
          Top = 60
          Width = 151
          Height = 14
          AutoSize = False
          Caption = 'unidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI2: TPanel
        Left = 193
        Top = 6
        Width = 175
        Height = 80
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 1
        object lblKPI2Cap: TLabel
          Left = 12
          Top = 10
          Width = 151
          Height = 15
          AutoSize = False
          Caption = 'Disponible'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI2Val: TLabel
          Left = 12
          Top = 28
          Width = 151
          Height = 32
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -24
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI2Sub: TLabel
          Left = 12
          Top = 60
          Width = 151
          Height = 14
          AutoSize = False
          Caption = 'saldo - reservado'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI3: TPanel
        Left = 374
        Top = 6
        Width = 175
        Height = 80
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 2
        object lblKPI3Cap: TLabel
          Left = 12
          Top = 10
          Width = 151
          Height = 15
          AutoSize = False
          Caption = 'D'#237'as cobertura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI3Val: TLabel
          Left = 12
          Top = 28
          Width = 151
          Height = 32
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -24
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI3Sub: TLabel
          Left = 12
          Top = 60
          Width = 151
          Height = 14
          AutoSize = False
          Caption = 'al ritmo actual'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI4: TPanel
        Left = 555
        Top = 6
        Width = 175
        Height = 80
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 3
        object lblKPI4Cap: TLabel
          Left = 12
          Top = 10
          Width = 151
          Height = 15
          AutoSize = False
          Caption = 'Pendiente recibir'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI4Val: TLabel
          Left = 12
          Top = 28
          Width = 151
          Height = 32
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -24
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI4Sub: TLabel
          Left = 12
          Top = 60
          Width = 151
          Height = 14
          AutoSize = False
          Caption = 'pedidos compra'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI5: TPanel
        Left = 736
        Top = 6
        Width = 175
        Height = 80
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 4
        object lblKPI5Cap: TLabel
          Left = 12
          Top = 10
          Width = 151
          Height = 15
          AutoSize = False
          Caption = 'Pendiente servir'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI5Val: TLabel
          Left = 12
          Top = 28
          Width = 151
          Height = 32
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -24
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI5Sub: TLabel
          Left = 12
          Top = 60
          Width = 151
          Height = 14
          AutoSize = False
          Caption = 'pedidos venta'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI6: TPanel
        Left = 917
        Top = 6
        Width = 175
        Height = 80
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 5
        object lblKPI6Cap: TLabel
          Left = 12
          Top = 10
          Width = 151
          Height = 15
          AutoSize = False
          Caption = 'Clasificaci'#243'n ABC'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI6Val: TLabel
          Left = 12
          Top = 28
          Width = 151
          Height = 32
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -24
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI6Sub: TLabel
          Left = 12
          Top = 60
          Width = 151
          Height = 14
          AutoSize = False
          Caption = 'por importe consumo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
    end
  end
  object pgcTabs: TcxPageControl
    Left = 0
    Top = 170
    Width = 1100
    Height = 485
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tabATP
    Properties.CustomButtons.Buttons = <>
    OnChange = pgcTabsChange
    ClientRectBottom = 573
    ClientRectLeft = 2
    ClientRectRight = 1098
    ClientRectTop = 27
    object tabDisponibilidad: TcxTabSheet
      Caption = 'Disponibilidad fabricaci'#243'n'
      object pnlDispTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
        Height = 70
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblDispCantidad: TLabel
          Left = 12
          Top = 12
          Width = 92
          Height = 15
          Caption = 'Cantidad fabricar:'
        end
        object lblDispFecha: TLabel
          Left = 240
          Top = 12
          Width = 88
          Height = 15
          Caption = 'Fecha objetivo:'
        end
        object lblDispVeredicto: TLabel
          Left = 480
          Top = 8
          Width = 600
          Height = 25
          AutoSize = False
          Caption = ''
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
          Caption = 'Tipo: P=Producto fabricado  S=Semielaborado  M=Materia prima  |  Estado: OK / FALTA / CRITICO'
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
          Value = 1
          Width = 110
        end
        object dtDispFecha: TDateTimePicker
          Left = 335
          Top = 9
          Width = 130
          Height = 23
          Date = 44562.000000000000000000
          Time = 0.000000000000000000
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
        Left = 0
        Top = 70
        Width = 1096
        Height = 476
        Align = alClient
        Bands = <
          item
          end>
        OptionsBehavior.CellHints = True
        OptionsData.Editing = False
        OptionsView.GridLines = tlglBoth
        OptionsView.ShowEditButtons = ecsbNever
        TabOrder = 1
        OnCustomDrawDataCell = tlDispCustomDrawDataCell
        object colDispArticulo: TcxTreeListColumn
          Caption.Text = 'Art'#237'culo'
          Width = 180
          Position.ColIndex = 0
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispDescripcion: TcxTreeListColumn
          Caption.Text = 'Descripci'#243'n'
          Width = 240
          Position.ColIndex = 1
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispTipo: TcxTreeListColumn
          Caption.Text = 'Tipo'
          Width = 50
          Position.ColIndex = 2
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispNecesario: TcxTreeListColumn
          Caption.Text = 'Necesario'
          Width = 90
          Position.ColIndex = 3
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispStockActual: TcxTreeListColumn
          Caption.Text = 'Stock actual'
          Width = 90
          Position.ColIndex = 4
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispStockProy: TcxTreeListColumn
          Caption.Text = 'Stock proyectado'
          Width = 110
          Position.ColIndex = 5
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispFaltaActual: TcxTreeListColumn
          Caption.Text = 'Falta hoy'
          Width = 80
          Position.ColIndex = 6
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispFaltaProy: TcxTreeListColumn
          Caption.Text = 'Falta proyect.'
          Width = 90
          Position.ColIndex = 7
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object colDispEstado: TcxTreeListColumn
          Caption.Text = 'Estado'
          Width = 70
          Position.ColIndex = 8
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
      end
    end
    object tabDondeUsa: TcxTabSheet
      Caption = 'D'#243'nde se usa'
      object pnlDondeUsaTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
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
          Caption = ''
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnRecargarDondeUsa: TButton
          Left = 970
          Top = 7
          Width = 110
          Height = 26
          Caption = 'Recargar'
          TabOrder = 0
          OnClick = btnRecargarDondeUsaClick
        end
      end
      object grdDondeUsa: TcxGrid
        Left = 0
        Top = 40
        Width = 1096
        Height = 506
        Align = alClient
        TabOrder = 1
        object grdDondeUsaView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.DataSource = dsDondeUsa
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GridLines = glBoth
        end
        object grdDondeUsaLevel: TcxGridLevel
          GridView = grdDondeUsaView
        end
      end
      object cdsDondeUsa: TClientDataSet
        Aggregates = <>
        Params = <>
        Left = 560
        Top = 200
      end
      object dsDondeUsa: TDataSource
        DataSet = cdsDondeUsa
        Left = 640
        Top = 200
      end
    end
    object tabHistorico: TcxTabSheet
      Caption = 'Hist'#243'rico'
      object pnlHistTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblHistMeses: TLabel
          Left = 12
          Top = 12
          Width = 41
          Height = 15
          Caption = 'Meses:'
        end
        object lblHistResumen: TLabel
          Left = 200
          Top = 12
          Width = 700
          Height = 17
          AutoSize = False
          Caption = ''
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
          Width = 80
          Height = 23
          Properties.MaxValue = 60.000000000000000000
          Properties.MinValue = 3.000000000000000000
          TabOrder = 0
          Value = 12
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
      object pbHistorico: TPaintBox
        Left = 0
        Top = 40
        Width = 1096
        Height = 506
        Align = alClient
        OnPaint = pbHistoricoPaint
      end
    end
    object tabOFs: TcxTabSheet
      Caption = 'OFs activas'
      object pnlOFsTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
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
          Caption = ''
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
        Width = 1096
        Height = 506
        Align = alClient
        TabOrder = 1
        object grdOFsView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.DataSource = dsOFs
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GridLines = glBoth
        end
        object grdOFsLevel: TcxGridLevel
          GridView = grdOFsView
        end
      end
      object cdsOFs: TClientDataSet
        Aggregates = <>
        Params = <>
        Left = 560
        Top = 200
      end
      object dsOFs: TDataSource
        DataSet = cdsOFs
        Left = 640
        Top = 200
      end
    end
    object tabProveedores: TcxTabSheet
      Caption = 'Proveedores'
      object pnlProvTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblProvMeses: TLabel
          Left = 12
          Top = 12
          Width = 89
          Height = 15
          Caption = 'Meses atr'#225's (0=todo):'
        end
        object lblProvResumen: TLabel
          Left = 220
          Top = 12
          Width = 700
          Height = 17
          AutoSize = False
          Caption = ''
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object seProvMeses: TcxSpinEdit
          Left = 110
          Top = 9
          Width = 80
          Height = 23
          Properties.MaxValue = 120.000000000000000000
          Properties.MinValue = 0.000000000000000000
          TabOrder = 0
          Value = 24
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
        Width = 1096
        Height = 506
        Align = alClient
        TabOrder = 1
        object grdProvView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.DataSource = dsProv
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GridLines = glBoth
        end
        object grdProvLevel: TcxGridLevel
          GridView = grdProvView
        end
      end
      object cdsProv: TClientDataSet
        Aggregates = <>
        Params = <>
        Left = 560
        Top = 200
      end
      object dsProv: TDataSource
        DataSet = cdsProv
        Left = 640
        Top = 200
      end
    end
    object tabClientes: TcxTabSheet
      Caption = 'Clientes'
      object pnlCliTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblCliMeses: TLabel
          Left = 12
          Top = 12
          Width = 89
          Height = 15
          Caption = 'Meses atr'#225's (0=todo):'
        end
        object lblCliResumen: TLabel
          Left = 220
          Top = 12
          Width = 700
          Height = 17
          AutoSize = False
          Caption = ''
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object seCliMeses: TcxSpinEdit
          Left = 110
          Top = 9
          Width = 80
          Height = 23
          Properties.MaxValue = 120.000000000000000000
          Properties.MinValue = 0.000000000000000000
          TabOrder = 0
          Value = 24
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
        Width = 1096
        Height = 506
        Align = alClient
        TabOrder = 1
        object grdCliView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.DataSource = dsCli
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GridLines = glBoth
        end
        object grdCliLevel: TcxGridLevel
          GridView = grdCliView
        end
      end
      object cdsCli: TClientDataSet
        Aggregates = <>
        Params = <>
        Left = 560
        Top = 200
      end
      object dsCli: TDataSource
        DataSet = cdsCli
        Left = 640
        Top = 200
      end
    end
    object tabMovimientos: TcxTabSheet
      Caption = 'Movimientos futuros'
      object pnlMovsFutTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblMovsFutDesde: TLabel
          Left = 12
          Top = 12
          Width = 40
          Height = 15
          Caption = 'Desde:'
        end
        object lblMovsFutHasta: TLabel
          Left = 195
          Top = 12
          Width = 38
          Height = 15
          Caption = 'Hasta:'
        end
        object lblMovsFutResumen: TLabel
          Left = 480
          Top = 12
          Width = 480
          Height = 17
          AutoSize = False
          Caption = ''
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
          Time = 0.000000000000000000
          TabOrder = 0
        end
        object dtMovsFutHasta: TDateTimePicker
          Left = 240
          Top = 9
          Width = 120
          Height = 23
          Date = 44562.000000000000000000
          Time = 0.000000000000000000
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
        Width = 1096
        Height = 506
        Align = alClient
        TabOrder = 1
        object grdMovsFutView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
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
          OptionsView.GridLines = glBoth
        end
        object grdMovsFutLevel: TcxGridLevel
          GridView = grdMovsFutView
        end
      end
    end
    object tabPartidas: TcxTabSheet
      Caption = 'Stock por partida / lote'
      object pnlPartidasTop: TPanel
        Left = 0
        Top = 0
        Width = 1096
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
          Caption = ''
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
        Width = 1096
        Height = 506
        Align = alClient
        TabOrder = 1
        object grdPartidasView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
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
          OptionsView.GridLines = glBoth
          OptionsView.Footer = True
        end
        object grdPartidasLevel: TcxGridLevel
          GridView = grdPartidasView
        end
      end
    end
    object tabATP: TcxTabSheet
      Caption = 'Projected Stock (ATP)'
      object pnlResumen: TPanel
        Left = 0
        Top = 0
        Width = 1096
        Height = 90
        Align = alTop
        BevelOuter = bvLowered
        Color = clInfoBk
        ParentBackground = False
        TabOrder = 0
        object lblTitResumen: TLabel
          Left = 12
          Top = 6
          Width = 60
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
          Width = 90
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
          Width = 120
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
          Width = 120
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
          Width = 120
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
          Width = 120
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
          Caption = ''
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Visible = False
        end
      end
      object pnlMovsContainer: TPanel
        Left = 0
        Top = 90
        Width = 1096
        Height = 456
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object grdMovs: TcxGrid
          Left = 0
          Top = 0
          Width = 1096
          Height = 456
          Align = alClient
          TabOrder = 0
          object grdMovsView: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
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
            OptionsView.GridLines = glBoth
          end
          object grdMovsLevel: TcxGridLevel
            GridView = grdMovsView
          end
        end
      end
    end
  end
  object splitLog: TSplitter
    Left = 0
    Top = 510
    Width = 1100
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 550
    ExplicitWidth = 100
  end
  object pnlLog: TPanel
    Left = 0
    Top = 515
    Width = 1100
    Height = 140
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object mmoLog: TMemo
      Left = 0
      Top = 0
      Width = 1100
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
    Top = 655
    Width = 1100
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCerrar: TButton
      Left = 980
      Top = 9
      Width = 100
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
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
