object frmGestionOperacionHabilidades: TfrmGestionOperacionHabilidades
  Left = 0
  Top = 0
  Caption = 'Habilidades requeridas por operaci'#243'n'
  ClientHeight = 580
  ClientWidth = 980
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
    Width = 980
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 18
      Width = 290
      Height = 21
      Caption = 'Habilidades requeridas por cada operaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 56
    Width = 220
    Height = 472
    Align = alLeft
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 1
    object lblOperaciones: TLabel
      Left = 8
      Top = 8
      Width = 84
      Height = 17
      Caption = 'Operaciones'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lbOperaciones: TListBox
      Left = 8
      Top = 32
      Width = 204
      Height = 432
      ItemHeight = 17
      TabOrder = 0
      OnClick = lbOperacionesClick
    end
  end
  object pnlMain: TPanel
    Left = 220
    Top = 56
    Width = 760
    Height = 472
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 2
    object pnlActions: TPanel
      Left = 0
      Top = 0
      Width = 760
      Height = 56
      Align = alTop
      BevelOuter = bvNone
      Color = 16579836
      ParentBackground = False
      TabOrder = 0
      object lblHabRequeridas: TLabel
        Left = 8
        Top = 32
        Width = 200
        Height = 17
        Caption = 'Habilidades requeridas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6316128
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object btnAdd: TcxButton
        Left = 8
        Top = 4
        Width = 100
        Height = 26
        Caption = '+ A'#241'adir'
        TabOrder = 0
        OnClick = btnAddClick
      end
      object btnEdit: TcxButton
        Left = 116
        Top = 4
        Width = 100
        Height = 26
        Caption = 'Editar nivel'
        TabOrder = 1
        OnClick = btnEditClick
      end
      object btnRemove: TcxButton
        Left = 224
        Top = 4
        Width = 100
        Height = 26
        Caption = 'Eliminar'
        TabOrder = 2
        OnClick = btnRemoveClick
      end
    end
    object grdReqs: TcxGrid
      Left = 0
      Top = 56
      Width = 760
      Height = 416
      Align = alClient
      TabOrder = 1
      object tvReqs: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        OnDblClick = tvReqsDblClick
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
        object colReq_Cod: TcxGridColumn
          Caption = 'Habilidad'
          Width = 160
        end
        object colReq_Desc: TcxGridColumn
          Caption = 'Descripci'#243'n'
          Width = 380
        end
        object colReq_Nivel: TcxGridColumn
          Caption = 'Nivel m'#237'nimo'
          Width = 160
        end
      end
      object lvReqs: TcxGridLevel
        GridView = tvReqs
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 528
    Width = 980
    Height = 52
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 3
    object btnCerrar: TcxButton
      Left = 884
      Top = 12
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
