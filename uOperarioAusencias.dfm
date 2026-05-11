object frmOperarioAusencias: TfrmOperarioAusencias
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de ausencias'
  ClientHeight = 660
  ClientWidth = 1100
  Color = 15789544
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
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
      Width = 249
      Height = 21
      Caption = 'Gesti'#243'n de ausencias por operario'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 612
    Width = 1100
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      1100
      48)
    object btnCerrar: TcxButton
      Left = 1004
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
  object pnlLeft: TPanel
    Left = 0
    Top = 56
    Width = 240
    Height = 556
    Align = alLeft
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 2
    object edBuscar: TEdit
      Left = 8
      Top = 8
      Width = 224
      Height = 25
      TabOrder = 0
      TextHint = 'Buscar operario...'
      OnChange = edBuscarChange
    end
    object cbFiltroDepto: TComboBox
      Left = 8
      Top = 40
      Width = 224
      Height = 25
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbFiltroDeptoChange
    end
    object grdOperarios: TcxGrid
      Left = 8
      Top = 72
      Width = 224
      Height = 476
      TabOrder = 2
      object tvOperarios: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        OnFocusedRecordChanged = tvOperariosFocusedRecordChanged
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsBehavior.IncSearch = True
        OptionsCustomize.ColumnsQuickCustomization = True
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.GridLines = glHorizontal
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
        object colOpNombre: TcxGridColumn
          Caption = 'Operario'
          Width = 120
        end
        object colOpTotal: TcxGridColumn
          Caption = 'Total'
          Width = 50
        end
        object colOpFiltro: TcxGridColumn
          Caption = 'Filtro'
          Width = 50
        end
      end
      object lvOperarios: TcxGridLevel
        GridView = tvOperarios
      end
    end
  end
  object pnlMain: TPanel
    Left = 240
    Top = 56
    Width = 860
    Height = 556
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 3
    object pcMain: TPageControl
      Left = 0
      Top = 0
      Width = 860
      Height = 556
      ActivePage = tsLista
      Align = alClient
      TabOrder = 0
      object tsLista: TTabSheet
        Caption = 'Lista'
        object pnlListaTop: TPanel
          Left = 0
          Top = 0
          Width = 852
          Height = 56
          Align = alTop
          BevelOuter = bvNone
          Color = 16579836
          ParentBackground = False
          TabOrder = 0
          DesignSize = (
            852
            56)
          object btnNueva: TcxButton
            Left = 8
            Top = 14
            Width = 100
            Height = 28
            Caption = '+ Nueva'
            TabOrder = 0
            OnClick = btnNuevaClick
          end
          object btnEditar: TcxButton
            Left = 116
            Top = 14
            Width = 90
            Height = 28
            Caption = 'Editar'
            TabOrder = 1
            OnClick = btnEditarClick
          end
          object btnEliminar: TcxButton
            Left = 214
            Top = 14
            Width = 90
            Height = 28
            Caption = 'Eliminar'
            TabOrder = 2
            OnClick = btnEliminarClick
          end
          object btnDuplicar: TcxButton
            Left = 312
            Top = 14
            Width = 90
            Height = 28
            Caption = 'Duplicar'
            TabOrder = 3
            OnClick = btnDuplicarClick
          end
          object cbFiltroAno: TComboBox
            Left = 432
            Top = 16
            Width = 90
            Height = 25
            Style = csDropDownList
            TabOrder = 4
            OnChange = cbFiltroAnoChange
          end
          object cbFiltroTipo: TComboBox
            Left = 530
            Top = 16
            Width = 140
            Height = 25
            Style = csDropDownList
            TabOrder = 5
            OnChange = cbFiltroTipoChange
          end
          object btnExportarCsv: TcxButton
            Left = 746
            Top = 14
            Width = 100
            Height = 28
            Anchors = [akTop, akRight]
            Caption = 'Exportar CSV'
            TabOrder = 6
            OnClick = btnExportarCsvClick
          end
        end
        object grdAusencias: TcxGrid
          Left = 0
          Top = 56
          Width = 852
          Height = 468
          Align = alClient
          TabOrder = 1
          object tvAusencias: TcxGridTableView
            OnDblClick = tvAusenciasDblClick
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            OnCustomDrawCell = tvAusenciasCustomDrawCell
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsBehavior.IncSearch = True
            OptionsCustomize.ColumnsQuickCustomization = True
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.CellSelect = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colTipo: TcxGridColumn
              Caption = 'Tipo'
              Width = 140
            end
            object colInicio: TcxGridColumn
              Caption = 'Inicio'
              Width = 140
            end
            object colFin: TcxGridColumn
              Caption = 'Fin'
              Width = 140
            end
            object colDias: TcxGridColumn
              Caption = 'Duraci'#243'n'
              Width = 80
            end
            object colDescripcion: TcxGridColumn
              Caption = 'Descripci'#243'n'
              Width = 360
            end
          end
          object lvAusencias: TcxGridLevel
            GridView = tvAusencias
          end
        end
      end
      object tsCalendario: TTabSheet
        Caption = 'Calendario'
        object lblLegendaCal: TLabel
          Left = 0
          Top = 504
          Width = 852
          Height = 20
          Align = alBottom
          Alignment = taCenter
          AutoSize = False
          Caption = 'Vacaciones    Baja    Formaci'#243'n    Permiso    Otros'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 6316128
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlCenter
          ExplicitTop = 506
          ExplicitWidth = 280
        end
        object pnlCalTop: TPanel
          Left = 0
          Top = 0
          Width = 852
          Height = 56
          Align = alTop
          BevelOuter = bvNone
          Color = 16579836
          ParentBackground = False
          TabOrder = 0
          object lblMesAno: TLabel
            Left = 200
            Top = 18
            Width = 65
            Height = 21
            Caption = 'Mes A'#241'o'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 4210752
            Font.Height = -16
            Font.Name = 'Segoe UI Semibold'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object btnPrevMes: TcxButton
            Left = 8
            Top = 14
            Width = 60
            Height = 28
            Caption = '<'
            TabOrder = 0
            OnClick = btnPrevMesClick
          end
          object btnHoyCal: TcxButton
            Left = 76
            Top = 14
            Width = 60
            Height = 28
            Caption = 'Hoy'
            TabOrder = 1
            OnClick = btnHoyCalClick
          end
          object btnNextMes: TcxButton
            Left = 144
            Top = 14
            Width = 50
            Height = 28
            Caption = '>'
            TabOrder = 2
            OnClick = btnNextMesClick
          end
        end
        object pnlCalHost: TPanel
          Left = 0
          Top = 56
          Width = 852
          Height = 448
          Align = alClient
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 1
        end
      end
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'csv'
    Filter = 'CSV (*.csv)|*.csv|Todos (*.*)|*.*'
    Left = 1000
    Top = 70
  end
end
