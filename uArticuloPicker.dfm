object frmArticuloPicker: TfrmArticuloPicker
  Left = 0
  Top = 0
  Caption = 'Seleccionar art'#237'culo'
  ClientHeight = 500
  ClientWidth = 700
  Color = clBtnFace
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
    Width = 700
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblFiltro: TLabel
      Left = 12
      Top = 16
      Width = 67
      Height = 15
      Caption = 'Buscar (c'#243'd/desc):'
    end
    object edFiltro: TEdit
      Left = 100
      Top = 12
      Width = 480
      Height = 23
      TabOrder = 0
      TextHint = 'Substring del c'#243'digo (vac'#237'o = todos)'
      OnKeyPress = edFiltroKeyPress
    end
    object btnBuscar: TButton
      Left = 588
      Top = 11
      Width = 90
      Height = 25
      Caption = 'Buscar'
      Default = True
      TabOrder = 1
      OnClick = btnBuscarClick
    end
  end
  object grdArticulos: TcxGrid
    Left = 0
    Top = 50
    Width = 700
    Height = 405
    Align = alClient
    TabOrder = 1
    object grdArticulosView: TcxGridDBTableView
      Navigator.Buttons.CustomButtons = <>
      OnDblClick = grdArticulosViewDblClick
      DataController.DataSource = dsArticulos
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.DeletingConfirmation = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsCustomize.ColumnsQuickCustomization = True
      OptionsSelection.CellSelect = False
      OptionsView.GridLines = glBoth
    end
    object grdArticulosLevel: TcxGridLevel
      GridView = grdArticulosView
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 455
    Width = 700
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnAceptar: TButton
      Left = 480
      Top = 8
      Width = 100
      Height = 30
      Caption = 'Aceptar'
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TButton
      Left = 588
      Top = 8
      Width = 100
      Height = 30
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object cdsArticulos: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 200
    Top = 100
  end
  object dsArticulos: TDataSource
    DataSet = cdsArticulos
    Left = 256
    Top = 100
  end
end
