object frmBacklog: TfrmBacklog
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Backlog / Carga pendiente'
  ClientHeight = 719
  ClientWidth = 1296
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1296
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1296
      70)
    object lblTitle: TLabel
      Left = 68
      Top = 4
      Width = 291
      Height = 32
      Caption = 'Backlog / Carga pendiente'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 68
      Top = 38
      Width = 261
      Height = 15
      Caption = 'OFs, pedidos y proyectos pendientes de planificar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object pnlKpiOF: TPanel
      Left = 996
      Top = 10
      Width = 95
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 5
      object lblKpiOFVal: TLabel
        Left = 0
        Top = 4
        Width = 95
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiOFCap: TLabel
        Left = 0
        Top = 28
        Width = 95
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'OF pend.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiOT: TPanel
      Left = 1093
      Top = 10
      Width = 95
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 6
      object lblKpiOTVal: TLabel
        Left = 0
        Top = 4
        Width = 95
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiOTCap: TLabel
        Left = 0
        Top = 28
        Width = 95
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'OT pend.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiOP: TPanel
      Left = 1190
      Top = 10
      Width = 95
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 7
      object lblKpiOPVal: TLabel
        Left = 0
        Top = 4
        Width = 95
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiOPCap: TLabel
        Left = 0
        Top = 28
        Width = 95
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'OP pend.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object btnToggleImpacto: TButton
      Left = 676
      Top = 11
      Width = 160
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Ocultar panel impacto'
      TabOrder = 0
      OnClick = btnToggleImpactoClick
    end
    object btnSelectAll: TButton
      Left = 494
      Top = 11
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Seleccionar'
      TabOrder = 2
      OnClick = btnSelectAllClick
    end
    object btnDeselectAll: TButton
      Left = 580
      Top = 11
      Width = 90
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Deseleccionar'
      TabOrder = 3
      OnClick = btnDeselectAllClick
    end
    object cxButton2: TcxButton
      Left = 676
      Top = 39
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Opciones'
      Colors.Normal = 14145497
      Colors.Hot = 11522481
      Colors.Disabled = 14737632
      Colors.DisabledText = clSilver
      DropDownMenu = PopupMenu1
      Enabled = False
      Kind = cxbkOfficeDropDown
      LookAndFeel.SkinName = ''
      SpeedButtonOptions.CanBeFocused = False
      TabOrder = 1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object imgSection: TcxImage
      AlignWithMargins = True
      Left = 3
      Top = 6
      Margins.Top = 6
      Margins.Right = 5
      Margins.Bottom = 12
      Align = alLeft
      Picture.Data = {
        0D546478536D617274496D6167653C3F786D6C2076657273696F6E3D22312E30
        2220656E636F64696E673D225554462D38223F3E0D0A3C737667207669657742
        6F783D223020302032342032342220786D6C6E733D22687474703A2F2F777777
        2E77332E6F72672F323030302F737667223E0D0A093C706174682066696C6C3D
        2223464646464646222066696C6C2D6F7061636974793D22302E352220643D22
        4D31392034483556323048313956345A4D3320322E39393138433320322E3434
        34303520332E3434373439203220332E3939383520324831392E393939374332
        302E3535313920322032302E3939393620322E34343737322032302E39393937
        20334C32312032302E393932354332312032312E353438392032302E35353531
        2032322032302E3030363620323248332E3939333443332E3434343736203232
        20332032312E3534343720332032312E3030383256322E393931385A4D31312E
        323932392031332E313231334C31352E3533353520382E38373836384C31362E
        393439372031302E323932394C31312E323932392031352E393439374C372E34
        303338312031322E303630374C382E38313830322031302E363436344C31312E
        323932392031332E313231335A222F3E0D0A3C2F7376673E0D0A}
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Properties.ShowFocusRect = False
      Style.BorderStyle = ebsNone
      TabOrder = 4
      Transparent = True
      Height = 52
      Width = 56
    end
  end
  object pnlFiltros: TPanel
    Left = 0
    Top = 152
    Width = 240
    Height = 567
    Align = alLeft
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 1
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
    object lblCountRegs: TLabel
      Left = 16
      Top = 502
      Width = 54
      Height = 13
      Caption = '0 registros'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
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
    Left = 976
    Top = 152
    Width = 320
    Height = 567
    Align = alRight
    BevelOuter = bvNone
    Color = 16446704
    ParentBackground = False
    TabOrder = 2
    DesignSize = (
      320
      567)
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
      Height = 333
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
    Top = 124
    Width = 1290
    Height = 25
    Margins.Top = 10
    Align = alTop
    TabOrder = 3
    Tabs.Strings = (
      'Pendientes de planificar'
      'Planificados')
    TabIndex = 0
    OnChange = tabModeChange
  end
  object grdBacklog: TcxGrid
    Left = 240
    Top = 152
    Width = 736
    Height = 567
    Align = alClient
    TabOrder = 4
    object tvBacklog: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      OnCellDblClick = tvBacklogCellDblClick
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
  object pnlSubTitulo: TPanel
    Left = 0
    Top = 70
    Width = 1296
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    Color = 7699523
    ParentBackground = False
    TabOrder = 5
    DesignSize = (
      1296
      44)
    object lblNivelVista: TLabel
      Left = 480
      Top = 12
      Width = 27
      Height = 15
      Caption = 'Nivel'
    end
    object Label28: TLabel
      Left = 1194
      Top = 11
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
    object btnDesplanificarSel: TButton
      Left = 702
      Top = 6
      Width = 148
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Desplanificar selecci'#243'n'
      TabOrder = 0
      Visible = False
      OnClick = btnDesplanificarSelClick
    end
    object cmbNivelVista: TComboBox
      Left = 514
      Top = 8
      Width = 170
      Height = 23
      Style = csDropDownList
      TabOrder = 7
      OnChange = cmbNivelVistaChange
      Items.Strings = (
        'Nivel 1 (OF / Pedido / Proyecto)'
        'Nivel 2 (OT / L'#237'nea / Tarea)'
        'Nivel 3 (OP)')
    end
    object btnPlanificar: TButton
      Left = 16
      Top = 6
      Width = 133
      Height = 28
      Caption = 'Planificar selecci'#243'n...'
      Default = True
      TabOrder = 1
      OnClick = btnPlanificarClick
    end
    object btnSyncErp: TcxButton
      Left = 155
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Sincronizar ERP...'
      TabOrder = 2
      OnClick = btnSyncErpClick
    end
    object btnVerOF: TcxButton
      Left = 301
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Ver OF...'
      TabOrder = 6
      OnClick = btnVerOFClick
    end
    object btnDesplanificarTodo: TButton
      Left = 856
      Top = 6
      Width = 121
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Desplanificar TODO'
      TabOrder = 3
      Visible = False
      OnClick = btnDesplanificarTodoClick
    end
    object cxButton1: TcxButton
      Left = 1007
      Top = 6
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
      TabOrder = 4
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnRecargar: TcxButton
      Left = 1080
      Top = 6
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
      TabOrder = 5
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      OnClick = btnRecargarClick
    end
    object cxButton9: TcxButton
      Left = 1266
      Top = 12
      Width = 18
      Height = 18
      Cursor = crHandPoint
      Anchors = [akTop, akRight]
      DropDownMenu = PopupMenu2
      Kind = cxbkDropDown
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
      TabOrder = 8
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 528
    Top = 72
    object RegenerarNodosDemo1: TMenuItem
      Caption = 'Regenerar nodos del proyecto (demo)...'
      OnClick = RegenerarNodosDemo1Click
    end
    object RegenerarBacklogDemo1: TMenuItem
      Caption = 'Regenerar Backlog (demo: OF / Comandas / Proyectos)...'
      OnClick = RegenerarBacklogDemo1Click
    end
  end
  object PopupMenu2: TPopupMenu
    Left = 416
    Top = 80
    object Columnas1: TMenuItem
      Caption = 'Columnas'
      object Configurar1: TMenuItem
        Caption = 'Columnas personalizadas...'
        OnClick = Configurar1Click
      end
      object Guardar1: TMenuItem
        Caption = 'Guardar layout grid'
        OnClick = Guardar1Click
      end
      object Restablecer1: TMenuItem
        Caption = 'Restablecer layout grid'
        OnClick = Restablecer1Click
      end
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object Vaciarylimpiartodalaplanificacin2: TMenuItem
      Caption = 'Vaciar y limpiar toda la planificaci'#243'n'
      OnClick = Vaciarylimpiartodalaplanificacin2Click
    end
  end
end
