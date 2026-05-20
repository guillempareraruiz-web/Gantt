object frmOperacionPicker: TfrmOperacionPicker
  Left = 0
  Top = 0
  Caption = 'Seleccionar operaci'#243'n'
  ClientHeight = 460
  ClientWidth = 560
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 560
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 220
      Height = 21
      Caption = 'Operaciones disponibles'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblFiltro: TLabel
      Left = 16
      Top = 32
      Width = 60
      Height = 15
      Caption = 'Filtro:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlFiltro: TPanel
    Left = 0
    Top = 56
    Width = 560
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object edFiltro: TEdit
      Left = 8
      Top = 8
      Width = 440
      Height = 23
      TabOrder = 0
      OnChange = edFiltroChange
    end
    object btnLimpiar: TButton
      Left = 456
      Top = 6
      Width = 90
      Height = 28
      Caption = 'Limpiar'
      TabOrder = 1
      OnClick = btnLimpiarClick
    end
  end
  object gridOps: TcxGrid
    Left = 0
    Top = 96
    Width = 560
    Height = 324
    Align = alClient
    TabOrder = 2
    object tvOps: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      OnDblClick = tvOpsDblClick
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 180
      end
      object colDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 340
      end
    end
    object lvOps: TcxGridLevel
      GridView = tvOps
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 420
    Width = 560
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnOK: TButton
      Left = 340
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 448
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 500
    Top = 12
  end
end
