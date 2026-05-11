object frmGestionHabilidades: TfrmGestionHabilidades
  Left = 0
  Top = 0
  Caption = 'Habilidades / Polivalencia'
  ClientHeight = 520
  ClientWidth = 720
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
    Width = 720
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 18
      Width = 215
      Height = 21
      Caption = 'Cat'#225'logo de habilidades / Polivalencia'
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
    Width = 720
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
  object grdHabilidades: TcxGrid
    Left = 0
    Top = 104
    Width = 720
    Height = 360
    Align = alClient
    TabOrder = 2
    object tvHabilidades: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      OnDblClick = tvHabilidadesDblClick
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsBehavior.IncSearch = True
      OptionsCustomize.ColumnsQuickCustomization = True
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.Indicator = True
      OptionsView.GroupByBox = False
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 180
      end
      object colDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 510
      end
    end
    object lvHabilidades: TcxGridLevel
      GridView = tvHabilidades
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 464
    Width = 720
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 3
    object btnCerrar: TcxButton
      Left = 624
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
