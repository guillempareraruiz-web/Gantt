object frmAutoPlanificacion: TfrmAutoPlanificacion
  Left = 0
  Top = 0
  Caption = 'Auto-planificaci'#243'n (preview)'
  ClientHeight = 640
  ClientWidth = 1100
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
    Width = 1100
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 18
      Width = 261
      Height = 21
      Caption = 'Preview de planificaci'#243'n autom'#225'tica'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlSettings: TPanel
    Left = 0
    Top = 56
    Width = 1100
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      1100
      48)
    object lblFecha: TLabel
      Left = 16
      Top = 14
      Width = 149
      Height = 17
      Caption = 'Fecha/hora de referencia:'
    end
    object dtpFecha: TDateTimePicker
      Left = 184
      Top = 12
      Width = 120
      Height = 25
      Date = 45000.000000000000000000
      Time = 45000.000000000000000000
      TabOrder = 0
    end
    object dtpHora: TDateTimePicker
      Left = 312
      Top = 12
      Width = 80
      Height = 25
      Date = 45000.000000000000000000
      Time = 0.333333333335758700
      Kind = dtkTime
      TabOrder = 1
    end
    object btnRecalcular: TcxButton
      Left = 416
      Top = 10
      Width = 100
      Height = 28
      Caption = 'Recalcular'
      TabOrder = 2
      OnClick = btnRecalcularClick
    end
    object btnEditarPesos: TcxButton
      Left = 980
      Top = 10
      Width = 100
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Editar pesos'
      TabOrder = 3
      OnClick = btnEditarPesosClick
    end
  end
  object pcResult: TPageControl
    Left = 0
    Top = 104
    Width = 1100
    Height = 472
    ActivePage = tsAsigs
    Align = alClient
    TabOrder = 2
    object tsAsigs: TTabSheet
      Caption = 'Asignaciones'
      object grdAsigs: TcxGrid
        Left = 0
        Top = 0
        Width = 1092
        Height = 440
        Align = alClient
        TabOrder = 0
        object tvAsigs: TcxGridTableView
          OnDblClick = tvAsigsDblClick
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsBehavior.IncSearch = True
          OptionsCustomize.ColumnsQuickCustomization = True
          OptionsData.Editing = True
          OptionsSelection.CellSelect = True
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colA_Node: TcxGridColumn
            Caption = 'Node ID'
            Options.Editing = False
            Width = 80
          end
          object colA_Operacion: TcxGridColumn
            Caption = 'Operaci'#243'n'
            Options.Editing = False
            Width = 180
          end
          object colA_Operario: TcxGridColumn
            Caption = 'Operario'
            Options.Editing = False
            Width = 200
          end
          object colA_Score: TcxGridColumn
            Caption = 'Score'
            Options.Editing = False
            Width = 90
          end
          object colA_Coste: TcxGridColumn
            Caption = 'Coste'
            Options.Editing = False
            Width = 100
          end
          object colA_Inicio: TcxGridColumn
            Caption = 'Inicio'
            Options.Editing = False
            Width = 110
          end
          object colA_Fin: TcxGridColumn
            Caption = 'Fin'
            Options.Editing = False
            Width = 110
          end
          object colA_Argumento: TcxGridColumn
            Caption = 'Argumento'
            PropertiesClassName = 'TcxButtonEditProperties'
            Properties.Buttons = <
              item
                Caption = 'Ver'
                Default = True
                Kind = bkText
                Width = 50
              end>
            Properties.ReadOnly = True
            Properties.ViewStyle = vsHideCursor
            Properties.OnButtonClick = colA_ArgumentoButtonClick
            Options.ShowEditButtons = isebAlways
            Width = 80
          end
        end
        object lvAsigs: TcxGridLevel
          GridView = tvAsigs
        end
      end
    end
    object tsNoAsig: TTabSheet
      Caption = 'No asignables'
      object grdNoAsig: TcxGrid
        Left = 0
        Top = 0
        Width = 1092
        Height = 442
        Align = alClient
        TabOrder = 0
        object tvNoAsig: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsBehavior.IncSearch = True
          OptionsData.Editing = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colN_Node: TcxGridColumn
            Caption = 'Node ID'
            Width = 80
          end
          object colN_Operacion: TcxGridColumn
            Caption = 'Operaci'#243'n'
            Width = 200
          end
          object colN_Motivo: TcxGridColumn
            Caption = 'Motivo'
            Width = 700
          end
        end
        object lvNoAsig: TcxGridLevel
          GridView = tvNoAsig
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 576
    Width = 1100
    Height = 64
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 3
    DesignSize = (
      1100
      64)
    object lblTotales: TLabel
      Left = 16
      Top = 22
      Width = 51
      Height = 17
      Caption = 'Totales...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnAplicar: TcxButton
      Left = 904
      Top = 18
      Width = 90
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Aplicar'
      Default = True
      TabOrder = 0
      OnClick = btnAplicarClick
    end
    object btnCancelar: TcxButton
      Left = 1000
      Top = 18
      Width = 90
      Height = 30
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
end
