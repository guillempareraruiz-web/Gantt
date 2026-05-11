object frmGestionOperationTypes: TfrmGestionOperationTypes
  Left = 0
  Top = 0
  Caption = 'Tipos de operaci'#243'n (paralelismo)'
  ClientHeight = 540
  ClientWidth = 820
  Color = 15789544
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 820
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 18
      Width = 250
      Height = 21
      Caption = 'Tipos de operaci'#243'n y paralelismo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlActions: TPanel
    Left = 0
    Top = 56
    Width = 820
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 1
    object btnNueva: TcxButton
      Left = 16
      Top = 10
      Width = 100
      Height = 28
      Caption = '+ Nueva'
      TabOrder = 0
      OnClick = btnNuevaClick
    end
    object btnEditar: TcxButton
      Left = 124
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Editar'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnEliminar: TcxButton
      Left = 222
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Eliminar'
      TabOrder = 2
      OnClick = btnEliminarClick
    end
  end
  object grdOps: TcxGrid
    Left = 0
    Top = 104
    Width = 820
    Height = 380
    Align = alClient
    TabOrder = 2
    object tvOps: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      OnDblClick = tvOpsDblClick
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsBehavior.IncSearch = True
      OptionsCustomize.ColumnsQuickCustomization = True
      OptionsData.Editing = False
      OptionsSelection.CellSelect = False
      OptionsView.Indicator = True
      OptionsView.GroupByBox = False
      object colOpCodigo: TcxGridColumn
        Caption = 'Operaci'#243'n'
        Width = 160
      end
      object colOpMax: TcxGridColumn
        Caption = 'M'#225'x. paralelos'
        Width = 110
      end
      object colOpFactor: TcxGridColumn
        Caption = 'Factor'
        Width = 100
      end
      object colOpDesc: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 420
      end
    end
    object lvOps: TcxGridLevel
      GridView = tvOps
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 484
    Width = 820
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 3
    object btnCerrar: TcxButton
      Left = 724
      Top = 14
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Cerrar'
      ModalResult = 2
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
end
