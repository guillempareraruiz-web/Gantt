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
  DesignSize = (
    1296
    719)
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
      Width = 203
      Height = 15
      Caption = 'OFs y pedidos pendientes de planificar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object pnlKpiVenc: TPanel
      Left = 700
      Top = 10
      Width = 95
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 4276680
      ParentBackground = False
      TabOrder = 4
      object lblKpiVencVal: TLabel
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
      object lblKpiVencCap: TLabel
        Left = 0
        Top = 28
        Width = 95
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Vencidas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiPron: TPanel
      Left = 797
      Top = 10
      Width = 95
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 2202336
      ParentBackground = False
      TabOrder = 5
      object lblKpiPronVal: TLabel
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
      object lblKpiPronCap: TLabel
        Left = 0
        Top = 28
        Width = 95
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Vencen 7d'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiSinF: TPanel
      Left = 894
      Top = 10
      Width = 95
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = clGray
      ParentBackground = False
      TabOrder = 6
      object lblKpiSinFVal: TLabel
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
      object lblKpiSinFCap: TLabel
        Left = 0
        Top = 28
        Width = 95
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Sin fecha'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
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
      TabOrder = 1
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
      TabOrder = 2
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
      TabOrder = 3
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
      TabOrder = 0
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
      Width = 84
      Height = 15
      Caption = 'Proyecto / Obra'
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
      Left = 174
      Top = 13
      Width = 54
      Height = 13
      Alignment = taRightJustify
      Caption = '0 registros'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object bvlBuscar: TBevel
      Left = 12
      Top = 432
      Width = 216
      Height = 2
      Shape = bsTopLine
    end
    object lblBuscar: TLabel
      Left = 12
      Top = 444
      Width = 106
      Height = 15
      Caption = 'Buscar OF / OT / OP'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblBuscarHint: TLabel
      Left = 12
      Top = 489
      Width = 216
      Height = 30
      AutoSize = False
      Caption = 'Busca en n'#186' de OF, serie, OT, OP, art'#237'culo y descripci'#243'n.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
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
        'MANUAL')
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
    object edtBuscar: TEdit
      Left = 12
      Top = 462
      Width = 216
      Height = 23
      TabOrder = 10
      TextHint = 'N'#186' OF, c'#243'digo OT u OP...'
      OnChange = FiltroChanged
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
      BorderStyle = cxcbsNone
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
    PopupMenu = pmGridRow
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
      OptionsSelection.MultiSelectMode = msmPersistent
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
    object cmbNivelVista: TComboBox
      Left = 514
      Top = 8
      Width = 170
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cmbNivelVistaChange
      Items.Strings = (
        'Nivel 1 (OF / Pedido)'
        'Nivel 2 (OT / L'#237'nea)'
        'Nivel 3 (OP)')
    end
    object cmbPersistMethod: TComboBox
      Left = 894
      Top = 7
      Width = 115
      Height = 23
      Style = csDropDownList
      Anchors = [akTop, akRight]
      ItemIndex = 0
      TabOrder = 4
      Text = 'Persist. M5 (bulk)'
      Visible = False
      Items.Strings = (
        'Persist. M5 (bulk)'
        'Persist. M4 (bulk ADO)'
        'Persist. M1 (clasica)')
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
        22307078222076696577426F783D223020302033322033322220656E61626C65
        2D6261636B67726F756E643D226E6577203020302033322033322220786D6C3A
        73706163653D227072657365727665223E262331333B262331303B3C67206F70
        61636974793D22302E36223E0D0A09093C7265637420783D22362220793D2238
        222066696C6C3D2223303130313031222077696474683D223230222068656967
        68743D2232222F3E0D0A09093C7265637420783D22362220793D223132222066
        696C6C3D2223303130313031222077696474683D22323022206865696768743D
        2232222F3E0D0A09093C7265637420783D22362220793D223136222066696C6C
        3D2223303130313031222077696474683D22323022206865696768743D223222
        2F3E0D0A09093C7265637420783D22362220793D223230222066696C6C3D2223
        303130313031222077696474683D22323022206865696768743D2232222F3E0D
        0A09093C7265637420783D22362220793D223234222066696C6C3D2223303130
        313031222077696474683D22323022206865696768743D2232222F3E0D0A093C
        2F673E0D0A3C2F7376673E0D0A}
      PaintStyle = bpsGlyph
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      SpeedButtonOptions.Transparent = True
      TabOrder = 1
    end
    object chkVerImpacto: TcxCheckBox
      Left = 1036
      Top = 11
      Anchors = [akTop, akRight]
      Caption = 'Panel impacto'
      Properties.OnChange = chkVerImpactoPropertiesChange
      Style.LookAndFeel.NativeStyle = False
      Style.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      Style.TextColor = clWhite
      Style.TransparentBorder = False
      StyleDisabled.LookAndFeel.NativeStyle = False
      StyleDisabled.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      StyleFocused.LookAndFeel.NativeStyle = False
      StyleFocused.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      StyleHot.LookAndFeel.NativeStyle = False
      StyleHot.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      StyleReadOnly.LookAndFeel.NativeStyle = False
      StyleReadOnly.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      TabOrder = 2
    end
    object chkVerFiltros: TcxCheckBox
      Left = 1143
      Top = 11
      Anchors = [akTop, akRight]
      Caption = 'Filtros'
      Properties.OnChange = chkVerFiltrosPropertiesChange
      State = cbsChecked
      Style.LookAndFeel.NativeStyle = False
      Style.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      Style.TextColor = clWhite
      Style.TransparentBorder = False
      StyleDisabled.LookAndFeel.NativeStyle = False
      StyleDisabled.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      StyleFocused.LookAndFeel.NativeStyle = False
      StyleFocused.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      StyleHot.LookAndFeel.NativeStyle = False
      StyleHot.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      StyleReadOnly.LookAndFeel.NativeStyle = False
      StyleReadOnly.LookAndFeel.SkinName = 'DevExpressDarkStyle'
      TabOrder = 3
    end
    object btnPlanificar: TcxButton
      AlignWithMargins = True
      Left = 12
      Top = 10
      Width = 93
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Caption = 'Planificar sel...'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 5
      OnClick = btnPlanificarClick
    end
    object btnPlanificarExpress: TcxButton
      AlignWithMargins = True
      Left = 111
      Top = 10
      Width = 129
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Caption = 'Planificaci'#243'n Express'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 6
      OnClick = btnPlanificarExpressClick
    end
    object btnDesplanificarSel: TcxButton
      AlignWithMargins = True
      Left = 246
      Top = 10
      Width = 113
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Caption = 'Desplanificar sel'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 7
      OnClick = btnDesplanificarSelClick
    end
  end
  object btnRecargar: TcxButton
    AlignWithMargins = True
    Left = 1225
    Top = 117
    Width = 60
    Height = 23
    Margins.Top = 5
    Margins.Bottom = 5
    Anchors = [akTop, akRight]
    Caption = 'Refrescar'
    LookAndFeel.Kind = lfOffice11
    LookAndFeel.NativeStyle = False
    LookAndFeel.SkinName = 'Office2010Silver'
    SpeedButtonOptions.GroupIndex = 1
    SpeedButtonOptions.CanBeFocused = False
    SpeedButtonOptions.Flat = True
    TabOrder = 6
    OnClick = btnRecargarClick
  end
  object btnSyncErp: TcxButton
    AlignWithMargins = True
    Left = 1111
    Top = 117
    Width = 107
    Height = 23
    Margins.Top = 5
    Margins.Bottom = 5
    Anchors = [akTop, akRight]
    Caption = 'Sincronizar ERP...'
    LookAndFeel.Kind = lfOffice11
    LookAndFeel.NativeStyle = False
    LookAndFeel.SkinName = 'Office2010Silver'
    SpeedButtonOptions.GroupIndex = 1
    SpeedButtonOptions.CanBeFocused = False
    SpeedButtonOptions.Flat = True
    TabOrder = 7
    OnClick = btnSyncErpClick
  end
  object btnLimpiarSeleccion: TcxButton
    AlignWithMargins = True
    Left = 1072
    Top = 117
    Width = 29
    Height = 23
    Margins.Top = 5
    Margins.Bottom = 5
    Anchors = [akTop, akRight]
    LookAndFeel.Kind = lfOffice11
    LookAndFeel.NativeStyle = False
    LookAndFeel.SkinName = 'Office2010Silver'
    OptionsImage.Glyph.SourceDPI = 96
    OptionsImage.Glyph.Data = {
      89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
      610000001F744558745469746C6500496E736572745461626C6543617074696F
      6E3B5461626C653B819BCC38000001C749444154785EA5524F4BD451143D6F18
      84FA025104B58870D12750AC08A4F52C82FE8088D1B65A887B5BB86C3F538894
      7E8668146C682A9082A05D09A5528886818B99C69977AFE7722F3E8870E30F0E
      F7DC73DEBBEFDEF77E09C0FF8063F3A2E5549B7DBBAA295D870A44A988428D33
      4A0EAE8C999EE6E00265ECF7BA1F52ED495BA76F0DE36040612038A0D9EF0B7A
      831C5A769DE89B177C40BC7EFF03551141A797D1FCBC6355210A42A0623C2060
      2EC10958EE9D548DECFEF98BDDBD8E2D281B25C62072E8A69112CC611148330B
      5F746EE20ACD30282EB67FE2EEE8390839E05DCDAF7CC7E48D8BE4A5C0E3FA47
      54C44BBA18468C02780C2F4E8771043882902DBDDB6652DA36FEB2B5891C6D67
      03B567CD75E79988E25525B93D72C647004CC4626B0BF7C6CE334F845FE2F3E5
      754C8D5F824AE9F25163CD47504D8811A26D5FE41EA2BB180331963101AA662C
      B57FF90D93678BC4C2EA86BF4016F754517FF535468A75507FC63B2367CBFBAA
      E2C59B0D4C5CBB50BAA0D7687EC3839B978F2E11C4C3FA9A5FA2A26C365304E5
      6781733F118144E623A7FB4F5BADCAD0A9AB2AF1076A39D5627946CF61115EA9
      BBFFFB93953A4D0C1115221D837F7D25BAC92A9FE43B043810F45DBEFACC9500
      00000049454E44AE426082}
    SpeedButtonOptions.GroupIndex = 1
    SpeedButtonOptions.CanBeFocused = False
    SpeedButtonOptions.Flat = True
    TabOrder = 8
    OnClick = btnLimpiarSeleccionClick
  end
  object btnLimpiarFiltrosGrid: TcxButton
    AlignWithMargins = True
    Left = 1037
    Top = 117
    Width = 29
    Height = 23
    Margins.Top = 5
    Margins.Bottom = 5
    Anchors = [akTop, akRight]
    LookAndFeel.Kind = lfOffice11
    LookAndFeel.NativeStyle = False
    LookAndFeel.SkinName = 'Office2010Silver'
    OptionsImage.Glyph.SourceDPI = 96
    OptionsImage.Glyph.Data = {
      89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
      610000001974455874536F6674776172650041646F626520496D616765526561
      647971C9653C0000002D744558745469746C6500436C6561722046696C746572
      3B46696C7465723B52656D6F76652046696C7465723B436C65617229F58C0200
      00007B49444154785EB5D1C109C0200C055077CA0ABD768A82037483ECD6213A
      455748B508C921FC44A487AF78F80F498A882CE53B9EEB9499FC02F004C01E90
      45B8A5B88022B80C0145FC320210B22B9E07EC66CA32701F5B6D9116EAA57E8F
      77CD026242F69D056CC98630A07BF710C23318E5CC0FA244330803B7F002CE38
      AC29FE0CE78A0000000049454E44AE426082}
    SpeedButtonOptions.GroupIndex = 1
    SpeedButtonOptions.CanBeFocused = False
    SpeedButtonOptions.Flat = True
    TabOrder = 9
    OnClick = btnLimpiarFiltrosGridClick
  end
  object PopupMenu1: TPopupMenu
    Left = 528
    Top = 72
    object RegenerarNodosDemo1: TMenuItem
      Caption = 'Regenerar nodos del proyecto (demo)...'
      OnClick = RegenerarNodosDemo1Click
    end
    object RegenerarBacklogDemo1: TMenuItem
      Caption = 'Regenerar Backlog (demo: OF / Comandas)...'
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
    object ConfigurarVencimiento1: TMenuItem
      Caption = 'Configurar aviso de vencimiento...'
      OnClick = ConfigurarVencimiento1Click
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object Vaciarylimpiartodalaplanificacin2: TMenuItem
      Caption = 'Vaciar y limpiar toda la planificaci'#243'n'
      OnClick = Vaciarylimpiartodalaplanificacin2Click
    end
  end
  object pmGridRow: TPopupMenu
    OnPopup = pmGridRowPopup
    Left = 560
    Top = 80
    object miVerFormula: TMenuItem
      Caption = 'Ver f'#243'rmula del art'#237'culo...'
      OnClick = miVerFormulaClick
    end
    object miVerDocumento: TMenuItem
      Caption = 'Ver documento de origen...'
      OnClick = miVerDocumentoClick
    end
    object N5: TMenuItem
      Caption = '-'
    end
    object miLimpiarSeleccion: TMenuItem
      Caption = 'Limpiar selecci'#243'n (incluida la oculta)'
      OnClick = miLimpiarSeleccionClick
    end
    object N6: TMenuItem
      Caption = '-'
    end
    object miCopiarCelda: TMenuItem
      Caption = 'Copiar celda'
      ShortCut = 16451
      OnClick = miCopiarCeldaClick
    end
  end
end
