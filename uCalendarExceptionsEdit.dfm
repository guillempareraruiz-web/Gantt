object frmCalendarExceptionsEdit: TfrmCalendarExceptionsEdit
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'Excepciones del calendario'
  ClientHeight = 480
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 12
      Top = 8
      Width = 211
      Height = 21
      Caption = 'Excepciones del calendario'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblCalendarNombre: TLabel
      Left = 12
      Top = 32
      Width = 200
      Height = 15
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 436
    Width = 760
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCerrar: TButton
      Left = 660
      Top = 10
      Width = 90
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Cerrar'
      Default = True
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 56
    Width = 760
    Height = 38
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object btnAdd: TButton
      Left = 12
      Top = 6
      Width = 90
      Height = 26
      Caption = 'A'#241'adir...'
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnEdit: TButton
      Left = 106
      Top = 6
      Width = 90
      Height = 26
      Caption = 'Editar...'
      TabOrder = 1
      OnClick = btnEditClick
    end
    object btnDel: TButton
      Left = 200
      Top = 6
      Width = 90
      Height = 26
      Caption = 'Eliminar'
      TabOrder = 2
      OnClick = btnDelClick
    end
    object btnDelSelected: TButton
      Left = 294
      Top = 6
      Width = 180
      Height = 26
      Caption = 'Eliminar seleccionadas'
      TabOrder = 3
      OnClick = btnDelSelectedClick
    end
    object lblTotales: TLabel
      Left = 484
      Top = 11
      Width = 260
      Height = 17
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
  object grdExc: TcxGrid
    Left = 0
    Top = 94
    Width = 760
    Height = 342
    Align = alClient
    TabOrder = 3
    object grdExcView: TcxGridDBTableView
      OnDblClick = grdExcViewDblClick
      DataController.DataSource = dsExc
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsCustomize.ColumnFiltering = True
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsSelection.MultiSelect = True
      OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
      OptionsSelection.ShowCheckBoxesDynamically = False
      OptionsView.GridLines = glBoth
      OptionsView.GroupByBox = False
      OptionsView.HeaderAutoHeight = True
      OptionsView.ColumnAutoWidth = True
      object colFecha: TcxGridDBColumn
        Caption = 'Fecha'
        DataBinding.FieldName = 'Fecha'
        Options.Editing = False
        Width = 140
      end
      object colTipo: TcxGridDBColumn
        Caption = 'Tipo'
        DataBinding.FieldName = 'Tipo'
        Options.Editing = False
        Width = 130
      end
      object colHorario: TcxGridDBColumn
        Caption = 'Horario'
        DataBinding.FieldName = 'Horario'
        Options.Editing = False
        Width = 100
      end
      object colDescripcion: TcxGridDBColumn
        Caption = 'Descripci'#243'n'
        DataBinding.FieldName = 'Descripcion'
        Options.Editing = False
        MinWidth = 200
        Width = 340
      end
    end
    object grdExcLevel: TcxGridLevel
      GridView = grdExcView
    end
  end
  object cdsExc: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 600
    Top = 10
  end
  object dsExc: TDataSource
    DataSet = cdsExc
    Left = 660
    Top = 10
  end
end
