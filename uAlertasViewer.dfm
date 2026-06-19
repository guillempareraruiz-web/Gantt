object frmAlertasViewer: TfrmAlertasViewer
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Alertas de planificaci'#243'n'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 19
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1000
      60)
    object lblTitulo: TLabel
      Left = 20
      Top = 16
      Width = 247
      Height = 30
      Caption = 'Excepciones detectadas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2236962
      Font.Height = -22
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSalud: TLabel
      Left = 628
      Top = 22
      Width = 130
      Height = 17
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'Actualizado hace 0 min'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 9145227
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object btnConfig: TButton
      Left = 840
      Top = 18
      Width = 82
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Configurar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnConfigClick
    end
    object Button1: TButton
      Left = 936
      Top = 18
      Width = 32
      Height = 28
      Anchors = [akTop, akRight]
      Caption = #8942
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -18
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
  end
  object pnlFiltros: TPanel
    Left = 0
    Top = 60
    Width = 1000
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      1000
      56)
    object cbGravedad: TComboBox
      Left = 20
      Top = 12
      Width = 180
      Height = 25
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnChange = FiltroChange
    end
    object cbTipo: TComboBox
      Left = 212
      Top = 12
      Width = 180
      Height = 25
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnChange = FiltroChange
    end
    object edtBuscar: TEdit
      Left = 404
      Top = 12
      Width = 260
      Height = 25
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      TextHint = 'Buscar...'
      OnChange = FiltroChange
    end
    object chkSoloIncidencias: TCheckBox
      Left = 684
      Top = 15
      Width = 200
      Height = 21
      Caption = 'Solo con incidencias'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2236962
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = FiltroChange
    end
    object btnVerTodas: TButton
      Left = 887
      Top = 12
      Width = 81
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Ver todas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = btnVerTodasClick
    end
  end
  object Grid: TcxGrid
    AlignWithMargins = True
    Left = 5
    Top = 119
    Width = 990
    Height = 429
    Margins.Left = 5
    Margins.Right = 5
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = cxcbsNone
    TabOrder = 2
    LookAndFeel.NativeStyle = False
    ExplicitLeft = 3
    ExplicitWidth = 994
    object tv: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      OnCustomDrawCell = tvCustomDrawCell
      OnDblClick = tvDblClick
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsBehavior.CellHints = True
      OptionsCustomize.ColumnFiltering = False
      OptionsCustomize.ColumnGrouping = False
      OptionsCustomize.ColumnMoving = False
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsSelection.HideFocusRectOnExit = False
      OptionsView.DataRowHeight = 52
      OptionsView.GroupByBox = False
      OptionsView.HeaderHeight = 44
      object colGravedad: TcxGridColumn
        Caption = 'Gravedad'
        PropertiesClassName = 'TcxTextEditProperties'
        Properties.Alignment.Horz = taCenter
        HeaderAlignmentHorz = taCenter
        Options.Editing = False
        Width = 130
      end
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'd.'
        PropertiesClassName = 'TcxTextEditProperties'
        Properties.Alignment.Horz = taCenter
        HeaderAlignmentHorz = taCenter
        Options.Editing = False
        Width = 80
      end
      object colFamilia: TcxGridColumn
        Caption = 'Familia'
        Options.Editing = False
        Width = 130
      end
      object colMotivo: TcxGridColumn
        Caption = 'Motivo'
        Options.Editing = False
        Width = 470
      end
      object colNodos: TcxGridColumn
        Caption = 'Nodos'
        PropertiesClassName = 'TcxTextEditProperties'
        Properties.Alignment.Horz = taCenter
        HeaderAlignmentHorz = taCenter
        Options.Editing = False
        Width = 90
      end
      object colPeso: TcxGridColumn
        Caption = 'Peso'
        PropertiesClassName = 'TcxTextEditProperties'
        Properties.Alignment.Horz = taCenter
        HeaderAlignmentHorz = taCenter
        Options.Editing = False
        Width = 90
      end
    end
    object lv: TcxGridLevel
      GridView = tv
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 551
    Width = 1000
    Height = 49
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 3
    object lblMaxRecords: TLabel
      AlignWithMargins = True
      Left = 20
      Top = 8
      Width = 317
      Height = 17
      Margins.Left = 20
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object lblResumen: TLabel
      AlignWithMargins = True
      Left = 20
      Top = 20
      Width = 605
      Height = 24
      Margins.Left = 20
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 9145227
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object btnFiltrar: TButton
      AlignWithMargins = True
      Left = 769
      Top = 9
      Width = 110
      Height = 31
      Margins.Left = 4
      Margins.Top = 9
      Margins.Right = 4
      Margins.Bottom = 9
      Align = alRight
      Caption = 'Ver en Gantt'
      TabOrder = 0
      OnClick = btnFiltrarClick
    end
    object btnCerrar: TButton
      AlignWithMargins = True
      Left = 887
      Top = 9
      Width = 98
      Height = 31
      Margins.Left = 4
      Margins.Top = 9
      Margins.Right = 15
      Margins.Bottom = 9
      Align = alRight
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
end
