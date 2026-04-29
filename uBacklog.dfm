object frmBacklog: TfrmBacklog
  Left = 0
  Top = 0
  Caption = 'Backlog / Carga pendiente'
  ClientHeight = 680
  ClientWidth = 1280
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  DesignSize = (
    1280
    680)
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1280
      60)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 226
      Height = 25
      Caption = 'Backlog / Carga pendiente'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 36
      Width = 274
      Height = 15
      Caption = 'OFs, comandas y proyectos pendientes de planificar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object Label28: TLabel
      Left = 1178
      Top = 0
      Width = 67
      Height = 19
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'Opciones'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object btnToggleImpacto: TButton
      Left = 810
      Top = 11
      Width = 160
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Ocultar panel impacto'
      TabOrder = 0
      OnClick = btnToggleImpactoClick
    end
    object lblCountRegs: TLabel
      Left = 320
      Top = 20
      Width = 300
      Height = 20
      Caption = '0 registros'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object btnSelectAll: TButton
      Left = 630
      Top = 11
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Seleccionar'
      TabOrder = 3
      OnClick = btnSelectAllClick
    end
    object btnDeselectAll: TButton
      Left = 714
      Top = 11
      Width = 90
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Deseleccionar'
      TabOrder = 4
      OnClick = btnDeselectAllClick
    end
    object cxButton9: TcxButton
      Left = 1250
      Top = 2
      Width = 18
      Height = 18
      Cursor = crHandPoint
      Anchors = [akTop, akRight]
      LookAndFeel.NativeStyle = False
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.SourceHeight = 16
      OptionsImage.Glyph.SourceWidth = 16
      OptionsImage.Glyph.Data = {
        3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
        462D38223F3E0D0A3C7376672076657273696F6E3D22312E31222069643D224C
        617965725F312220786D6C6E733D22687474703A2F2F7777772E77332E6F7267
        2F323030302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F77
        77772E77332E6F72672F313939392F786C696E6B2220783D223070782220793D
        22307078222076696577426F783D2230203020333220333222207374796C653D
        22656E61626C652D6261636B67726F756E643A6E657720302030203332203332
        3B2220786D6C3A73706163653D227072657365727665223E262331333B262331
        303B3C7374796C6520747970653D22746578742F6373732220786D6C3A737061
        63653D227072657365727665223E2E59656C6C6F777B66696C6C3A2346464231
        31353B7D262331333B262331303B2623393B2E5265647B66696C6C3A23443131
        4331433B7D262331333B262331303B2623393B2E426C75657B66696C6C3A2331
        31373744373B7D262331333B262331303B2623393B2E477265656E7B66696C6C
        3A233033394332333B7D262331333B262331303B2623393B2E426C61636B7B66
        696C6C3A233732373237323B7D262331333B262331303B2623393B2E57686974
        657B66696C6C3A234646464646463B7D262331333B262331303B2623393B2E73
        74307B6F7061636974793A302E353B7D262331333B262331303B2623393B2E73
        74317B646973706C61793A6E6F6E653B7D262331333B262331303B2623393B2E
        7374327B646973706C61793A696E6C696E653B66696C6C3A233033394332333B
        7D262331333B262331303B2623393B2E7374337B646973706C61793A696E6C69
        6E653B66696C6C3A234431314331433B7D262331333B262331303B2623393B2E
        7374347B646973706C61793A696E6C696E653B66696C6C3A233732373237323B
        7D3C2F7374796C653E0D0A3C672069643D22416C69676E4A757374696679223E
        0D0A09093C7061746820636C6173733D22426C61636B2220643D224D32382C38
        4834563668323456387A204D32382C3130483476326832345631307A204D3238
        2C3134483476326832345631347A204D32382C3232483476326832345632327A
        204D32382C3138483476326832345631387A222F3E0D0A093C2F673E0D0A3C2F
        7376673E0D0A}
      PaintStyle = bpsGlyph
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      SpeedButtonOptions.Transparent = True
      TabOrder = 1
    end
    object cxButton2: TcxButton
      Left = 1178
      Top = 25
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Opciones'
      Colors.Normal = 14145497
      Colors.Hot = 11522481
      Colors.Disabled = 14737632
      Colors.DisabledText = clSilver
      DropDownMenu = PopupMenu1
      Kind = cxbkOfficeDropDown
      LookAndFeel.SkinName = ''
      SpeedButtonOptions.CanBeFocused = False
      TabOrder = 2
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 640
    Width = 1280
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      1280
      40)
    object btnPlanificar: TButton
      Left = 0
      Top = 6
      Width = 133
      Height = 28
      Caption = 'Planificar selecci'#243'n...'
      Default = True
      TabOrder = 0
      OnClick = btnPlanificarClick
    end
    object btnDesplanificarSel: TButton
      Left = 686
      Top = 6
      Width = 148
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Desplanificar selecci'#243'n'
      TabOrder = 4
      Visible = False
      OnClick = btnDesplanificarSelClick
    end
    object btnDesplanificarTodo: TButton
      Left = 840
      Top = 6
      Width = 121
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Desplanificar TODO'
      TabOrder = 5
      Visible = False
      OnClick = btnDesplanificarTodoClick
    end
    object btnGuardarLayout: TButton
      Left = 368
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Guardar layout'
      TabOrder = 1
      OnClick = btnGuardarLayoutClick
    end
    object btnResetLayout: TButton
      Left = 514
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Restablecer layout'
      TabOrder = 2
      OnClick = btnResetLayoutClick
    end
    object btnAbrirGantt: TButton
      Left = 1064
      Top = 6
      Width = 98
      Height = 28
      Caption = 'Abrir Gantt'
      TabOrder = 6
      OnClick = btnAbrirGanttClick
    end
    object btnVaciarPlan: TButton
      Left = 139
      Top = 6
      Width = 76
      Height = 28
      Caption = 'Vaciar plan...'
      TabOrder = 7
      OnClick = btnVaciarPlanClick
    end
    object btnClose: TButton
      Left = 1168
      Top = 6
      Width = 100
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 3
      OnClick = btnCloseClick
    end
  end
  object pnlFiltros: TPanel
    Left = 0
    Top = 98
    Width = 240
    Height = 542
    Align = alLeft
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 2
    object lblFiltros: TLabel
      Left = 12
      Top = 10
      Width = 37
      Height = 17
      Caption = 'Filtros'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblFiltroOrigen: TLabel
      Left = 12
      Top = 40
      Width = 36
      Height = 15
      Caption = 'Origen'
    end
    object lblFiltroCliente: TLabel
      Left = 12
      Top = 88
      Width = 37
      Height = 15
      Caption = 'Cliente'
    end
    object lblFiltroProyecto: TLabel
      Left = 12
      Top = 136
      Width = 47
      Height = 15
      Caption = 'Proyecto'
    end
    object lblFiltroCentro: TLabel
      Left = 12
      Top = 184
      Width = 93
      Height = 15
      Caption = 'Centro preferente'
    end
    object lblFiltroEstado: TLabel
      Left = 12
      Top = 232
      Width = 35
      Height = 15
      Caption = 'Estado'
    end
    object lblFiltroFechaDesde: TLabel
      Left = 12
      Top = 280
      Width = 121
      Height = 15
      Caption = 'Fecha compromiso >='
    end
    object lblFiltroFechaHasta: TLabel
      Left = 12
      Top = 328
      Width = 121
      Height = 15
      Caption = 'Fecha compromiso <='
    end
    object cmbOrigen: TComboBox
      Left = 12
      Top = 58
      Width = 216
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = FiltroChanged
      Items.Strings = (
        '(Todos)'
        'OF'
        'PEDIDO'
        'PROYECTO')
    end
    object edtCliente: TEdit
      Left = 12
      Top = 106
      Width = 216
      Height = 23
      TabOrder = 1
      TextHint = '(cualquiera)'
      OnChange = FiltroChanged
    end
    object edtProyecto: TEdit
      Left = 12
      Top = 154
      Width = 216
      Height = 23
      TabOrder = 2
      TextHint = '(cualquiera)'
      OnChange = FiltroChanged
    end
    object edtCentro: TEdit
      Left = 12
      Top = 202
      Width = 216
      Height = 23
      TabOrder = 3
      TextHint = '(cualquiera)'
      OnChange = FiltroChanged
    end
    object edtEstado: TEdit
      Left = 12
      Top = 250
      Width = 216
      Height = 23
      TabOrder = 4
      TextHint = '(cualquiera)'
      OnChange = FiltroChanged
    end
    object dtFechaDesde: TDateTimePicker
      Left = 12
      Top = 298
      Width = 216
      Height = 23
      Date = 46134.000000000000000000
      Time = 0.967759039354859900
      TabOrder = 5
      OnChange = FiltroChanged
    end
    object dtFechaHasta: TDateTimePicker
      Left = 12
      Top = 346
      Width = 216
      Height = 23
      Date = 46134.000000000000000000
      Time = 0.967759039354859900
      TabOrder = 6
      OnChange = FiltroChanged
    end
    object chkUsaFechaDesde: TCheckBox
      Left = 140
      Top = 280
      Width = 90
      Height = 17
      Caption = 'Activar'
      TabOrder = 7
      OnClick = FiltroChanged
    end
    object chkUsaFechaHasta: TCheckBox
      Left = 140
      Top = 328
      Width = 90
      Height = 17
      Caption = 'Activar'
      TabOrder = 8
      OnClick = FiltroChanged
    end
    object btnLimpiarFiltros: TButton
      Left = 12
      Top = 390
      Width = 216
      Height = 28
      Caption = 'Limpiar filtros'
      TabOrder = 9
      OnClick = btnLimpiarFiltrosClick
    end
  end
  object pnlImpacto: TPanel
    Left = 960
    Top = 98
    Width = 320
    Height = 542
    Align = alRight
    BevelOuter = bvNone
    Color = 16446704
    ParentBackground = False
    TabOrder = 3
    DesignSize = (
      320
      542)
    object lblCargaTitulo: TLabel
      Left = 12
      Top = 232
      Width = 86
      Height = 13
      Caption = 'Carga por centro'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object pnlImpactoHeader: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 44
      Align = alTop
      BevelOuter = bvNone
      Color = 4602685
      ParentBackground = False
      TabOrder = 0
      object lblImpacto: TLabel
        Left = 16
        Top = 12
        Width = 158
        Height = 20
        Caption = 'Impacto de la selecci'#243'n'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -15
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
    end
    object vgResumen: TcxVerticalGrid
      Left = 0
      Top = 44
      Width = 320
      Height = 180
      Align = alTop
      OptionsView.PaintStyle = psDelphi
      OptionsView.RowHeaderWidth = 150
      OptionsData.Editing = False
      TabOrder = 1
      Version = 1
      object rowSelCount: TcxEditorRow
        Properties.Caption = 'Seleccionadas'
        Properties.Value = Null
        ID = 0
        ParentID = -1
        Index = 0
        Version = 1
      end
      object rowSelHoras: TcxEditorRow
        Properties.Caption = 'Horas totales'
        Properties.Value = Null
        ID = 1
        ParentID = -1
        Index = 1
        Version = 1
      end
      object rowFechaFinEst: TcxEditorRow
        Properties.Caption = 'Fecha fin estimada'
        Properties.Value = Null
        ID = 2
        ParentID = -1
        Index = 2
        Version = 1
      end
      object rowOFsFueraPlazo: TcxEditorRow
        Properties.Caption = 'OFs fuera de plazo'
        Properties.Value = Null
        ID = 3
        ParentID = -1
        Index = 3
        Version = 1
      end
      object rowCentrosSat: TcxEditorRow
        Properties.Caption = 'Centros sobrecargados'
        Properties.Value = Null
        ID = 4
        ParentID = -1
        Index = 4
        Version = 1
      end
      object rowVentana: TcxEditorRow
        Properties.Caption = 'Ventana c'#225'lculo'
        Properties.Value = Null
        ID = 5
        ParentID = -1
        Index = 5
        Version = 1
      end
    end
    object grdCargaCentro: TcxGrid
      Left = 6
      Top = 254
      Width = 308
      Height = 308
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 2
      object tvCargaCentro: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        OnCustomDrawCell = tvCargaCentroCustomDrawCell
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsCustomize.ColumnsQuickCustomization = True
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.ColumnAutoWidth = True
        OptionsView.GroupByBox = False
        object colCCCentro: TcxGridColumn
          Caption = 'Centro'
          Width = 90
        end
        object colCCHoras: TcxGridColumn
          Caption = 'Horas'
          Width = 55
        end
        object colCCCapacidad: TcxGridColumn
          Caption = 'Cap.'
          Width = 55
        end
        object colCCPct: TcxGridColumn
          Caption = '% Ocup.'
          Width = 100
        end
      end
      object lvCargaCentro: TcxGridLevel
        GridView = tvCargaCentro
      end
    end
  end
  object tabMode: TTabControl
    AlignWithMargins = True
    Left = 3
    Top = 70
    Width = 1274
    Height = 25
    Margins.Top = 10
    Align = alTop
    TabOrder = 4
    Tabs.Strings = (
      'Pendientes de planificar'
      'Planificados')
    TabIndex = 0
    OnChange = tabModeChange
  end
  object grdBacklog: TcxGrid
    Left = 240
    Top = 98
    Width = 720
    Height = 542
    Align = alClient
    TabOrder = 5
    object tvBacklog: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      OnSelectionChanged = tvBacklogSelectionChanged
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsBehavior.IncSearch = True
      OptionsCustomize.ColumnsQuickCustomization = True
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsSelection.MultiSelect = True
      OptionsView.Indicator = True
    end
    object lvBacklog: TcxGridLevel
      GridView = tvBacklog
    end
  end
  object btnRecargar: TcxButton
    Left = 1205
    Top = 63
    Width = 67
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Refrescar'
    Colors.Normal = 13492942
    Colors.Hot = 11522481
    Colors.Disabled = 14737632
    Colors.DisabledText = clSilver
    LookAndFeel.SkinName = ''
    SpeedButtonOptions.CanBeFocused = False
    TabOrder = 6
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    OnClick = btnRecargarClick
  end
  object cxButton1: TcxButton
    Left = 1132
    Top = 63
    Width = 67
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Planificar'
    Colors.Normal = 15395526
    Colors.Hot = 14540196
    Colors.Disabled = 14737632
    Colors.DisabledText = clSilver
    LookAndFeel.SkinName = ''
    SpeedButtonOptions.CanBeFocused = False
    TabOrder = 7
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object PopupMenu1: TPopupMenu
    Left = 736
    Top = 200
    object Guardarlayoutgrid1: TMenuItem
      Caption = 'Guardar layout grid'
    end
    object Guardarlayoutgrid2: TMenuItem
      Caption = 'Restablecer layout grid'
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Vaciarylimpiartodalaplanificacin1: TMenuItem
      Caption = 'Vaciar y limpiar toda la planificaci'#243'n'
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object RegenerarNodosDemo1: TMenuItem
      Caption = 'Regenerar nodos del proyecto (demo)...'
      OnClick = RegenerarNodosDemo1Click
    end
    object RegenerarBacklogDemo1: TMenuItem
      Caption = 'Regenerar Backlog (demo: OF / Comandas / Proyectos)...'
      OnClick = RegenerarBacklogDemo1Click
    end
  end
end
