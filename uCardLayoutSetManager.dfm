object frmCardLayoutSetManager: TfrmCardLayoutSetManager
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Gesti'#243'n de Card Layouts'
  ClientHeight = 600
  ClientWidth = 1090
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1090
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 192
      Height = 21
      Caption = 'Gesti'#243'n de Card Layouts'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 30
      Width = 348
      Height = 15
      Caption = 'Layouts privados y comunes. Doble clic para editar.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 50
    Width = 1090
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object lblFiltro: TLabel
      Left = 16
      Top = 12
      Width = 35
      Height = 15
      Caption = 'Filtro:'
    end
    object cmbFiltro: TComboBox
      Left = 60
      Top = 9
      Width = 130
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cmbFiltroChange
    end
    object btnNew: TButton
      Left = 220
      Top = 7
      Width = 90
      Height = 26
      Caption = 'Nuevo...'
      TabOrder = 1
      OnClick = btnNewClick
    end
    object btnEdit: TButton
      Left = 316
      Top = 7
      Width = 90
      Height = 26
      Caption = 'Editar'
      TabOrder = 2
      OnClick = btnEditClick
    end
    object btnDuplicate: TButton
      Left = 412
      Top = 7
      Width = 90
      Height = 26
      Caption = 'Duplicar'
      TabOrder = 3
      OnClick = btnDuplicateClick
    end
    object btnDelete: TButton
      Left = 508
      Top = 7
      Width = 90
      Height = 26
      Caption = 'Eliminar'
      TabOrder = 4
      OnClick = btnDeleteClick
    end
    object btnSetActive: TButton
      Left = 616
      Top = 7
      Width = 150
      Height = 26
      Caption = 'Marcar como activo'
      TabOrder = 5
      OnClick = btnSetActiveClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 562
    Width = 1090
    Height = 38
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object btnClose: TButton
      Left = 996
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 90
    Width = 1090
    Height = 472
    Align = alClient
    BevelOuter = bvNone
    Color = 15790320
    Padding.Left = 12
    Padding.Top = 8
    Padding.Right = 12
    Padding.Bottom = 8
    ParentBackground = False
    TabOrder = 3
    object pnlLeft: TPanel
      AlignWithMargins = True
      Left = 12
      Top = 8
      Width = 670
      Height = 456
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 8
      Margins.Bottom = 0
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object grid: TcxGrid
        Left = 0
        Top = 0
        Width = 670
        Height = 456
        Align = alClient
        TabOrder = 0
        object tv: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OnCustomDrawCell = tvCustomDrawCell
          OnFocusedRecordChanged = tvFocusedRecordChanged
          OnCellDblClick = tvCellDblClick
          OnEditValueChanged = tvEditValueChanged
          OnEditing = tvEditing
          OptionsBehavior.IncSearch = True
          OptionsCustomize.ColumnFiltering = False
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Editing = True
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = True
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colNombre: TcxGridColumn
            Caption = 'Nombre'
            Width = 220
          end
          object colScope: TcxGridColumn
            Caption = 'Tipo'
            PropertiesClassName = 'TcxComboBoxProperties'
            Properties.DropDownListStyle = lsFixedList
            Properties.Items.Strings = (
              'Privado'
              'Com'#250'n')
            Width = 90
          end
          object colCreadoPor: TcxGridColumn
            Caption = 'Creado por'
            Options.Editing = False
            Width = 110
          end
          object colActivo: TcxGridColumn
            Caption = 'Activo'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Width = 60
          end
          object colFechaMod: TcxGridColumn
            Caption = 'Modificado'
            Options.Editing = False
            Width = 140
          end
        end
        object lv: TcxGridLevel
          GridView = tv
        end
      end
    end
    object pnlRight: TPanel
      Left = 690
      Top = 8
      Width = 388
      Height = 456
      Align = alRight
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblPreview: TLabel
        Left = 12
        Top = 8
        Width = 105
        Height = 17
        Caption = 'Previsualizaci'#243'n'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4474440
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object cmbPreviewCategoria: TComboBox
        Left = 130
        Top = 6
        Width = 240
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = cmbPreviewCategoriaChange
      end
      object pbPreview: TPaintBox
        Left = 12
        Top = 40
        Width = 358
        Height = 400
        OnPaint = pbPreviewPaint
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    Left = 1030
    Top = 100
  end
end
