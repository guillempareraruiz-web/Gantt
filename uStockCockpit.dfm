object frmStockCockpit: TfrmStockCockpit
  Left = 0
  Top = 0
  Caption = 'Stock Cockpit'
  ClientHeight = 700
  ClientWidth = 1300
  Color = clBtnFace
  Constraints.MinHeight = 500
  Constraints.MinWidth = 1000
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
    Width = 1300
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblAlmacenes: TLabel
      Left = 12
      Top = 16
      Width = 61
      Height = 15
      Caption = 'Almacenes:'
    end
    object lblFamilia: TLabel
      Left = 500
      Top = 16
      Width = 41
      Height = 15
      Caption = 'Familia:'
    end
    object lblParam: TLabel
      Left = 760
      Top = 16
      Width = 78
      Height = 15
      Caption = 'D'#237'as horizonte:'
    end
    object lblContador: TLabel
      Left = 12
      Top = 36
      Width = 1000
      Height = 13
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object ccbAlmacenes: TcxCheckComboBox
      Left = 80
      Top = 12
      Properties.Items = <>
      TabOrder = 0
      Width = 400
    end
    object edFamilia: TEdit
      Left = 552
      Top = 12
      Width = 200
      Height = 23
      TabOrder = 1
      TextHint = 'C'#243'digo de familia (vac'#237'o = todas)'
    end
    object seParam: TcxSpinEdit
      Left = 884
      Top = 12
      Properties.AssignedValues.MinValue = True
      Properties.MaxValue = 9999.000000000000000000
      TabOrder = 2
      Width = 80
    end
    object btnActualizar: TButton
      Left = 1140
      Top = 11
      Width = 130
      Height = 26
      Caption = 'Actualizar'
      Default = True
      TabOrder = 3
      OnClick = btnActualizarClick
    end
  end
  object pgcTabs: TcxPageControl
    Left = 0
    Top = 50
    Width = 1300
    Height = 605
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tabCritico
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 603
    ClientRectLeft = 2
    ClientRectRight = 1298
    ClientRectTop = 25
    object tabCritico: TcxTabSheet
      Caption = 'Stock cr'#237'tico'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdCritico: TcxGrid
        Left = 0
        Top = 0
        Width = 1296
        Height = 576
        Align = alClient
        TabOrder = 0
        object grdCriticoView: TcxGridDBTableView
          OnDblClick = grdCriticoViewDblClick
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          OnCustomDrawCell = grdCriticoViewCustomDrawCell
          DataController.DataSource = dsCritico
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdCriticoLevel: TcxGridLevel
          GridView = grdCriticoView
        end
      end
    end
    object tabRupturas: TcxTabSheet
      Caption = 'Rupturas futuras'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdRupturas: TcxGrid
        Left = 0
        Top = 0
        Width = 1296
        Height = 576
        Align = alClient
        TabOrder = 0
        object grdRupturasView: TcxGridDBTableView
          OnDblClick = grdRupturasViewDblClick
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          OnCustomDrawCell = grdRupturasViewCustomDrawCell
          DataController.DataSource = dsRupturas
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdRupturasLevel: TcxGridLevel
          GridView = grdRupturasView
        end
      end
    end
    object tabObsoleto: TcxTabSheet
      Caption = 'Obsoleto'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdObsoleto: TcxGrid
        Left = 0
        Top = 0
        Width = 1296
        Height = 576
        Align = alClient
        TabOrder = 0
        object grdObsoletoView: TcxGridDBTableView
          OnDblClick = grdObsoletoViewDblClick
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.DataSource = dsObsoleto
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdObsoletoLevel: TcxGridLevel
          GridView = grdObsoletoView
        end
      end
    end
    object tabCobertura: TcxTabSheet
      Caption = 'Cobertura (DoS)'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdCobertura: TcxGrid
        Left = 0
        Top = 0
        Width = 1296
        Height = 576
        Align = alClient
        TabOrder = 0
        object grdCoberturaView: TcxGridDBTableView
          OnDblClick = grdCoberturaViewDblClick
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          OnCustomDrawCell = grdCoberturaViewCustomDrawCell
          DataController.DataSource = dsCobertura
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdCoberturaLevel: TcxGridLevel
          GridView = grdCoberturaView
        end
      end
    end
    object tabABC: TcxTabSheet
      Caption = 'An'#225'lisis ABC'
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdABC: TcxGrid
        Left = 0
        Top = 0
        Width = 1296
        Height = 576
        Align = alClient
        TabOrder = 0
        object grdABCView: TcxGridDBTableView
          OnDblClick = grdABCViewDblClick
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          OnCustomDrawCell = grdABCViewCustomDrawCell
          DataController.DataSource = dsABC
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
        end
        object grdABCLevel: TcxGridLevel
          GridView = grdABCView
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 655
    Width = 1300
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCerrar: TButton
      Left = 1180
      Top = 9
      Width = 100
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object cdsCritico: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 200
    Top = 250
  end
  object dsCritico: TDataSource
    DataSet = cdsCritico
    Left = 256
    Top = 250
  end
  object cdsRupturas: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 360
    Top = 250
  end
  object dsRupturas: TDataSource
    DataSet = cdsRupturas
    Left = 416
    Top = 250
  end
  object cdsObsoleto: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 520
    Top = 250
  end
  object dsObsoleto: TDataSource
    DataSet = cdsObsoleto
    Left = 576
    Top = 250
  end
  object cdsCobertura: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 680
    Top = 250
  end
  object dsCobertura: TDataSource
    DataSet = cdsCobertura
    Left = 736
    Top = 250
  end
  object cdsABC: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 840
    Top = 250
  end
  object dsABC: TDataSource
    DataSet = cdsABC
    Left = 896
    Top = 250
  end
end
