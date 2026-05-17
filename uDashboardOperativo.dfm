object frmDashboardOperativo: TfrmDashboardOperativo
  Left = 0
  Top = 0
  Caption = 'Dashboard operativo'
  ClientHeight = 720
  ClientWidth = 1280
  Color = clBtnFace
  Constraints.MinHeight = 600
  Constraints.MinWidth = 1100
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 130
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 10
      Width = 220
      Height = 23
      Caption = 'Dashboard operativo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 16
      Top = 32
      Width = 600
      Height = 15
      Caption = 'Pulso operativo de la planta'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnRefrescar: TButton
      Left = 1150
      Top = 12
      Width = 110
      Height = 30
      Caption = 'Refrescar'
      TabOrder = 0
      OnClick = btnRefrescarClick
    end
    object pnlKPIs: TPanel
      Left = 0
      Top = 55
      Width = 1280
      Height = 75
      Align = alBottom
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object pnlKPI1: TPanel
        Left = 12
        Top = 0
        Width = 200
        Height = 70
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 0
        object lblKPI1Cap: TLabel
          Left = 12
          Top = 8
          Width = 176
          Height = 14
          AutoSize = False
          Caption = 'OFs en curso'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI1Val: TLabel
          Left = 12
          Top = 22
          Width = 176
          Height = 28
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -21
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI1Sub: TLabel
          Left = 12
          Top = 52
          Width = 176
          Height = 13
          AutoSize = False
          Caption = 'ordenes activas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -10
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI2: TPanel
        Left = 218
        Top = 0
        Width = 200
        Height = 70
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 1
        object lblKPI2Cap: TLabel
          Left = 12
          Top = 8
          Width = 176
          Height = 14
          AutoSize = False
          Caption = 'OFs retrasadas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI2Val: TLabel
          Left = 12
          Top = 22
          Width = 176
          Height = 28
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -21
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI2Sub: TLabel
          Left = 12
          Top = 52
          Width = 176
          Height = 13
          AutoSize = False
          Caption = 'fecha fin < hoy'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -10
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI3: TPanel
        Left = 424
        Top = 0
        Width = 200
        Height = 70
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 2
        object lblKPI3Cap: TLabel
          Left = 12
          Top = 8
          Width = 176
          Height = 14
          AutoSize = False
          Caption = 'Rupturas 30 d'#237'as'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI3Val: TLabel
          Left = 12
          Top = 22
          Width = 176
          Height = 28
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -21
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI3Sub: TLabel
          Left = 12
          Top = 52
          Width = 176
          Height = 13
          AutoSize = False
          Caption = 'articulos en riesgo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -10
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI4: TPanel
        Left = 630
        Top = 0
        Width = 200
        Height = 70
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 3
        object lblKPI4Cap: TLabel
          Left = 12
          Top = 8
          Width = 176
          Height = 14
          AutoSize = False
          Caption = 'Stock cr'#237'tico'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI4Val: TLabel
          Left = 12
          Top = 22
          Width = 176
          Height = 28
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -21
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI4Sub: TLabel
          Left = 12
          Top = 52
          Width = 176
          Height = 13
          AutoSize = False
          Caption = 'bajo m'#237'nimo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -10
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI5: TPanel
        Left = 836
        Top = 0
        Width = 200
        Height = 70
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 4
        object lblKPI5Cap: TLabel
          Left = 12
          Top = 8
          Width = 176
          Height = 14
          AutoSize = False
          Caption = 'Stock obsoleto (6m)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI5Val: TLabel
          Left = 12
          Top = 22
          Width = 176
          Height = 28
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -21
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI5Sub: TLabel
          Left = 12
          Top = 52
          Width = 176
          Height = 13
          AutoSize = False
          Caption = '€ inmovilizados'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -10
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlKPI6: TPanel
        Left = 1042
        Top = 0
        Width = 218
        Height = 70
        BevelOuter = bvNone
        Color = 4210752
        ParentBackground = False
        TabOrder = 5
        object lblKPI6Cap: TLabel
          Left = 12
          Top = 8
          Width = 194
          Height = 14
          AutoSize = False
          Caption = 'Cartera pendiente servir'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14079702
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblKPI6Val: TLabel
          Left = 12
          Top = 22
          Width = 194
          Height = 28
          AutoSize = False
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -21
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblKPI6Sub: TLabel
          Left = 12
          Top = 52
          Width = 194
          Height = 13
          AutoSize = False
          Caption = '€ vendidos no entregados'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12303291
          Font.Height = -10
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 130
    Width = 1280
    Height = 590
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object pnlTopLeft: TPanel
      Left = 0
      Top = 0
      Width = 640
      Height = 295
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object lblTopRupt: TLabel
        Left = 8
        Top = 4
        Width = 624
        Height = 17
        Align = alTop
        Caption = '  Top 10 rupturas previstas (30 d'#237'as)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitWidth = 192
      end
      object grdRupt: TcxGrid
        Left = 0
        Top = 24
        Width = 640
        Height = 271
        Align = alClient
        TabOrder = 0
        object grdRuptView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          OnDblClick = grdRuptViewDblClick
          DataController.DataSource = dsRupt
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GridLines = glBoth
          OptionsView.GroupByBox = False
        end
        object grdRuptLevel: TcxGridLevel
          GridView = grdRuptView
        end
      end
    end
    object splitV: TSplitter
      Left = 640
      Top = 0
      Width = 5
      Height = 295
      ExplicitHeight = 590
    end
    object pnlTopRight: TPanel
      Left = 645
      Top = 0
      Width = 635
      Height = 295
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lblTopCrit: TLabel
        Left = 8
        Top = 4
        Width = 619
        Height = 17
        Align = alTop
        Caption = '  Top 10 stock cr'#237'tico (Disponible < M'#237'nimo)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitWidth = 220
      end
      object grdCrit: TcxGrid
        Left = 0
        Top = 24
        Width = 635
        Height = 271
        Align = alClient
        TabOrder = 0
        object grdCritView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          OnDblClick = grdCritViewDblClick
          DataController.DataSource = dsCrit
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GridLines = glBoth
          OptionsView.GroupByBox = False
        end
        object grdCritLevel: TcxGridLevel
          GridView = grdCritView
        end
      end
    end
    object splitH: TSplitter
      Left = 0
      Top = 295
      Width = 1280
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      ExplicitTop = 280
      ExplicitWidth = 100
    end
    object pnlBot: TPanel
      Left = 0
      Top = 300
      Width = 1280
      Height = 290
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object pnlBotLeft: TPanel
        Left = 0
        Top = 0
        Width = 640
        Height = 290
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblTopOF: TLabel
          Left = 8
          Top = 4
          Width = 624
          Height = 17
          Align = alTop
          Caption = '  OFs imminentes (fecha fin m'#225's pr'#243'xima)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitWidth = 204
        end
        object grdOF: TcxGrid
          Left = 0
          Top = 24
          Width = 640
          Height = 266
          Align = alClient
          TabOrder = 0
          object grdOFView: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
            OnDblClick = grdOFViewDblClick
            DataController.DataSource = dsOF
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.CellSelect = False
            OptionsView.GridLines = glBoth
            OptionsView.GroupByBox = False
          end
          object grdOFLevel: TcxGridLevel
            GridView = grdOFView
          end
        end
      end
      object splitV2: TSplitter
        Left = 640
        Top = 0
        Width = 5
        Height = 290
        ExplicitHeight = 290
      end
      object pnlBotRight: TPanel
        Left = 645
        Top = 0
        Width = 635
        Height = 290
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblTopA: TLabel
          Left = 8
          Top = 4
          Width = 619
          Height = 17
          Align = alTop
          Caption = '  Articulos A sin stock (top valor consumo)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitWidth = 218
        end
        object grdA: TcxGrid
          Left = 0
          Top = 24
          Width = 635
          Height = 266
          Align = alClient
          TabOrder = 0
          object grdAView: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
            OnDblClick = grdAViewDblClick
            DataController.DataSource = dsA
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.CellSelect = False
            OptionsView.GridLines = glBoth
            OptionsView.GroupByBox = False
          end
          object grdALevel: TcxGridLevel
            GridView = grdAView
          end
        end
      end
    end
  end
  object cdsRupt: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 100
    Top = 400
  end
  object dsRupt: TDataSource
    DataSet = cdsRupt
    Left = 160
    Top = 400
  end
  object cdsCrit: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 230
    Top = 400
  end
  object dsCrit: TDataSource
    DataSet = cdsCrit
    Left = 290
    Top = 400
  end
  object cdsOF: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 360
    Top = 400
  end
  object dsOF: TDataSource
    DataSet = cdsOF
    Left = 420
    Top = 400
  end
  object cdsA: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 490
    Top = 400
  end
  object dsA: TDataSource
    DataSet = cdsA
    Left = 550
    Top = 400
  end
end
