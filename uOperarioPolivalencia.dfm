object frmOperarioPolivalencia: TfrmOperarioPolivalencia
  Left = 0
  Top = 0
  Caption = 'Polivalencia y coste'
  ClientHeight = 580
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
      Width = 200
      Height = 21
      Caption = 'Polivalencia y coste'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlCoste: TPanel
    Left = 0
    Top = 56
    Width = 820
    Height = 96
    Align = alTop
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 1
    object lblCoste: TLabel
      Left = 16
      Top = 8
      Width = 92
      Height = 17
      Caption = 'Coste laboral'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSueldo: TLabel
      Left = 16
      Top = 32
      Width = 95
      Height = 17
      Caption = 'Sueldo EUR/hora'
    end
    object lblRecargoNoche: TLabel
      Left = 192
      Top = 32
      Width = 168
      Height = 17
      Caption = 'Recargo noche (multiplic.)'
    end
    object lblRecargoFestivo: TLabel
      Left = 376
      Top = 32
      Width = 165
      Height = 17
      Caption = 'Recargo festivo (multiplic.)'
    end
    object edSueldoEurHora: TEdit
      Left = 16
      Top = 52
      Width = 160
      Height = 25
      Alignment = taRightJustify
      TabOrder = 0
      Text = '0.00'
    end
    object edRecargoNoche: TEdit
      Left = 192
      Top = 52
      Width = 160
      Height = 25
      Alignment = taRightJustify
      TabOrder = 1
      Text = '1.0000'
    end
    object edRecargoFestivo: TEdit
      Left = 376
      Top = 52
      Width = 160
      Height = 25
      Alignment = taRightJustify
      TabOrder = 2
      Text = '1.0000'
    end
    object btnGuardarCoste: TcxButton
      Left = 568
      Top = 50
      Width = 140
      Height = 28
      Caption = 'Guardar coste'
      TabOrder = 3
      OnClick = btnGuardarCosteClick
    end
  end
  object pnlActions: TPanel
    Left = 0
    Top = 152
    Width = 820
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 2
    object lblHabilidades: TLabel
      Left = 8
      Top = 24
      Width = 130
      Height = 17
      Caption = 'Habilidades operario'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6316128
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnAdd: TcxButton
      Left = 8
      Top = 0
      Width = 100
      Height = 24
      Caption = '+ A'#241'adir'
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnEdit: TcxButton
      Left = 116
      Top = 0
      Width = 100
      Height = 24
      Caption = 'Editar'
      TabOrder = 1
      OnClick = btnEditClick
    end
    object btnRemove: TcxButton
      Left = 224
      Top = 0
      Width = 100
      Height = 24
      Caption = 'Eliminar'
      TabOrder = 2
      OnClick = btnRemoveClick
    end
  end
  object grdHabs: TcxGrid
    Left = 0
    Top = 200
    Width = 820
    Height = 332
    Align = alClient
    TabOrder = 3
    object tvHabs: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      OnDblClick = tvHabsDblClick
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
      object colH_Cod: TcxGridColumn
        Caption = 'Habilidad'
        Width = 160
      end
      object colH_Desc: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 360
      end
      object colH_Nivel: TcxGridColumn
        Caption = 'Nivel'
        Width = 160
      end
      object colH_Factor: TcxGridColumn
        Caption = 'Factor'
        Width = 100
      end
    end
    object lvHabs: TcxGridLevel
      GridView = tvHabs
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 532
    Width = 820
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 4
    object btnCerrar: TcxButton
      Left = 724
      Top = 10
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
