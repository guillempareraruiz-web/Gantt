object frmOFInspector: TfrmOFInspector
  Left = 0
  Top = 0
  Caption = 'Inspector de OF'
  ClientHeight = 640
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
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 8
      Width = 200
      Height = 21
      Caption = 'Inspector de OF'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -17
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCodigoOF: TLabel
      Left = 18
      Top = 30
      Width = 800
      Height = 15
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object vg: TcxVerticalGrid
    Left = 0
    Top = 50
    Width = 380
    Height = 545
    Align = alLeft
    TabOrder = 1
    OptionsBehavior.GoToNextCellOnEnter = True
    OptionsData.Editing = False
    OptionsView.RowHeaderWidth = 170
    Version = 1
  end
  object splitV: TSplitter
    Left = 380
    Top = 50
    Width = 5
    Height = 545
    ExplicitLeft = 376
    ExplicitTop = 88
    ExplicitHeight = 100
  end
  object pcDetail: TcxPageControl
    Left = 385
    Top = 50
    Width = 715
    Height = 545
    Align = alClient
    TabOrder = 3
    Properties.ActivePage = tabOTs
    Properties.CustomButtons.Buttons = <>
    OnChange = pcDetailChange
    ClientRectBottom = 543
    ClientRectLeft = 2
    ClientRectRight = 713
    ClientRectTop = 27
    object tabOTs: TcxTabSheet
      Caption = #211'rdenes de trabajo (OTs)'
      object grdOT: TcxGrid
        Left = 0
        Top = 0
        Width = 711
        Height = 516
        Align = alClient
        TabOrder = 0
        object grdOTView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          OnDblClick = grdOTViewDblClick
          DataController.DataSource = dsOT
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
        object grdOTLevel: TcxGridLevel
          GridView = grdOTView
        end
      end
    end
    object tabOperaciones: TcxTabSheet
      Caption = 'Operaciones'
      object pnlOpTop: TPanel
        Left = 0
        Top = 0
        Width = 711
        Height = 30
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblOpInfo: TLabel
          Left = 8
          Top = 8
          Width = 600
          Height = 15
          Caption = 'Selecciona una OT en la pesta'#241'a anterior para ver sus operaciones.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object grdOp: TcxGrid
        Left = 0
        Top = 30
        Width = 711
        Height = 486
        Align = alClient
        TabOrder = 1
        object grdOpView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.DataSource = dsOp
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
        object grdOpLevel: TcxGridLevel
          GridView = grdOpView
        end
      end
    end
    object tabConsumos: TcxTabSheet
      Caption = 'Consumos'
      object pnlConTop: TPanel
        Left = 0
        Top = 0
        Width = 711
        Height = 30
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblConInfo: TLabel
          Left = 8
          Top = 8
          Width = 600
          Height = 15
          Caption = 'Selecciona una OT en la pesta'#241'a anterior para ver sus consumos.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object grdCon: TcxGrid
        Left = 0
        Top = 30
        Width = 711
        Height = 486
        Align = alClient
        TabOrder = 1
        object grdConView: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          OnDblClick = grdConViewDblClick
          DataController.DataSource = dsCon
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
        object grdConLevel: TcxGridLevel
          GridView = grdConView
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 595
    Width = 1100
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object btnVerArticulo: TButton
      Left = 16
      Top = 9
      Width = 200
      Height = 30
      Caption = 'Ver art'#237'culo fabricado...'
      TabOrder = 0
      OnClick = btnVerArticuloClick
    end
    object btnCerrar: TButton
      Left = 980
      Top = 9
      Width = 100
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
  object cdsOT: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 500
    Top = 200
  end
  object dsOT: TDataSource
    DataSet = cdsOT
    Left = 560
    Top = 200
  end
  object cdsOp: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 630
    Top = 200
  end
  object dsOp: TDataSource
    DataSet = cdsOp
    Left = 690
    Top = 200
  end
  object cdsCon: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 760
    Top = 200
  end
  object dsCon: TDataSource
    DataSet = cdsCon
    Left = 820
    Top = 200
  end
end
