object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'FS Planner 2026: Empresa Demo'
  ClientHeight = 740
  ClientWidth = 1092
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Menu = MainMenu1
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlOldGantt: TPanel
    Left = 8
    Top = 52
    Width = 1089
    Height = 397
    TabOrder = 0
    Visible = False
    object pnlCentros: TPanel
      Left = 1
      Top = 114
      Width = 226
      Height = 282
      Align = alLeft
      BevelOuter = bvNone
      Caption = 'pnlCentros'
      TabOrder = 0
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 226
        Height = 48
        Align = alTop
        BevelOuter = bvNone
        Color = 15395562
        ParentBackground = False
        TabOrder = 0
        object Shape1: TShape
          Left = 0
          Top = 47
          Width = 226
          Height = 1
          Align = alBottom
          Brush.Color = clSilver
          Pen.Color = clSilver
          ExplicitTop = 41
        end
        object Shape2: TShape
          Left = 225
          Top = 0
          Width = 1
          Height = 47
          Align = alRight
          Brush.Color = clSilver
          Pen.Color = clSilver
          ExplicitLeft = 0
          ExplicitTop = 46
          ExplicitHeight = 226
        end
      end
    end
    object pnlGanttContainer: TPanel
      Left = 289
      Top = 137
      Width = 269
      Height = 253
      BevelOuter = bvNone
      Caption = 'pnlGanttContainer'
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
    end
    object pnlToolbar: TPanel
      Left = 1
      Top = 1
      Width = 1087
      Height = 113
      Align = alTop
      Color = 15395562
      ParentBackground = False
      TabOrder = 2
      DesignSize = (
        1087
        113)
      object Label1: TLabel
        Left = 288
        Top = 15
        Width = 41
        Height = 15
        Caption = 'Centros'
      end
      object Label2: TLabel
        Left = 351
        Top = 15
        Width = 48
        Height = 15
        Caption = 'Total OFs'
      end
      object Label3: TLabel
        Left = 23
        Top = 15
        Width = 95
        Height = 15
        Caption = 'Fecha Inicio Gantt'
      end
      object Label4: TLabel
        Left = 150
        Top = 15
        Width = 80
        Height = 15
        Caption = 'Fecha fin Gantt'
      end
      object Label5: TLabel
        Left = 777
        Top = 14
        Width = 35
        Height = 15
        Anchors = [akTop, akRight]
        Caption = 'Buscar'
      end
      object Label6: TLabel
        Left = 629
        Top = 15
        Width = 48
        Height = 15
        Anchors = [akTop, akRight]
        Caption = 'Ir a fecha'
      end
      object Label7: TLabel
        Left = 619
        Top = 58
        Width = 78
        Height = 15
        Anchors = [akTop, akRight]
        Caption = 'Zoom timeline'
      end
      object lblUndoCount: TLabel
        Left = 23
        Top = 91
        Width = 23
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblRedoCount: TLabel
        Left = 45
        Top = 91
        Width = 23
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label19: TLabel
        Left = 155
        Top = 70
        Width = 51
        Height = 15
        Caption = 'Operarios'
      end
      object btnRefresh: TButton
        Left = 1009
        Top = 30
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Refrescar'
        TabOrder = 0
        OnClick = btnRefreshClick
      end
      object spCentros: TcxSpinEdit
        Left = 288
        Top = 31
        Properties.AssignedValues.MinValue = True
        Properties.ImmediatePost = True
        TabOrder = 1
        Value = 3
        Width = 57
      end
      object cxSpinEdit2: TcxSpinEdit
        Left = 351
        Top = 31
        Properties.AssignedValues.MinValue = True
        Properties.ImmediatePost = True
        TabOrder = 2
        Value = 30
        Width = 66
      end
      object dtFechaInicioGantt: TcxDateEdit
        Left = 21
        Top = 31
        Properties.ShowTime = False
        TabOrder = 3
        Width = 121
      end
      object dtFechaFinGantt: TcxDateEdit
        Left = 148
        Top = 31
        Properties.ShowTime = False
        TabOrder = 4
        Width = 121
      end
      object SearchBox1: TSearchBox
        Left = 777
        Top = 31
        Width = 145
        Height = 23
        Anchors = [akTop, akRight]
        TabOrder = 5
        Text = 'SearchBox1'
        OnInvokeSearch = SearchBox1InvokeSearch
      end
      object RadioButton1: TRadioButton
        Left = 834
        Top = 14
        Width = 40
        Height = 17
        Anchors = [akTop, akRight]
        Caption = 'OF'
        Checked = True
        TabOrder = 6
        TabStop = True
      end
      object RadioButton2: TRadioButton
        Left = 880
        Top = 14
        Width = 40
        Height = 17
        Anchors = [akTop, akRight]
        Caption = 'OT'
        TabOrder = 7
      end
      object Button3: TButton
        Left = 926
        Top = 30
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'X'
        TabOrder = 8
        OnClick = Button3Click
      end
      object Button4: TButton
        Left = 950
        Top = 30
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = '<'
        TabOrder = 9
        OnClick = Button4Click
      end
      object Button5: TButton
        Left = 974
        Top = 30
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = '>'
        TabOrder = 10
        OnClick = Button5Click
      end
      object Button6: TButton
        Left = 423
        Top = 29
        Width = 75
        Height = 25
        Caption = 'Recrear Raw'
        TabOrder = 11
        OnClick = Button6Click
      end
      object cxDateEdit1: TcxDateEdit
        Left = 627
        Top = 31
        Anchors = [akTop, akRight]
        Properties.ShowTime = False
        TabOrder = 12
        Width = 94
      end
      object Button7: TButton
        Left = 721
        Top = 30
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Go'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 13
        OnClick = Button7Click
      end
      object Button8: TButton
        Tag = 1
        Left = 619
        Top = 73
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'H'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 14
        OnClick = Button8Click
      end
      object Button9: TButton
        Tag = 2
        Left = 643
        Top = 73
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'D'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 15
        OnClick = Button8Click
      end
      object Button10: TButton
        Tag = 3
        Left = 667
        Top = 73
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'S'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 16
        OnClick = Button8Click
      end
      object Button11: TButton
        Tag = 4
        Left = 691
        Top = 73
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'M'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 17
        OnClick = Button8Click
      end
      object ComboBox1: TComboBox
        Left = 831
        Top = 74
        Width = 253
        Height = 23
        Style = csDropDownList
        Anchors = [akTop, akRight]
        ItemIndex = 1
        TabOrder = 18
        Text = 'Solo ver dependencias del seleccionado'
        OnChange = ComboBox1Change
        Items.Strings = (
          'Ver todas las dependencias'
          'Solo ver dependencias del seleccionado'
          'Nunca ver dependencias')
      end
      object Button1: TButton
        Left = 745
        Top = 30
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Now'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 19
        OnClick = Button1Click
      end
      object btnUndo: TButton
        Tag = 1
        Left = 21
        Top = 67
        Width = 25
        Height = 25
        Caption = 'Undo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 20
        OnClick = btnUndoClick
      end
      object btnRedo: TButton
        Tag = 1
        Left = 45
        Top = 67
        Width = 25
        Height = 25
        Caption = 'Redo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 21
        OnClick = btnRedoClick
      end
      object Button12: TButton
        Tag = 1
        Left = 71
        Top = 67
        Width = 39
        Height = 25
        Caption = 'Check'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 22
        OnClick = Button12Click
      end
      object Button13: TButton
        Tag = 1
        Left = 722
        Top = 73
        Width = 52
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Weekends'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 23
        OnClick = Button13Click
      end
      object FcxFilterOperarios: TcxCheckComboBox
        Left = 154
        Top = 86
        Properties.DropDownRows = 30
        Properties.Items = <>
        Properties.OnChange = FcxFilterOperariosPropertiesChange
        TabOrder = 24
        Width = 185
      end
      object FchkSoloFiltrados: TcxCheckBox
        Left = 229
        Top = 67
        Caption = 'Ver solo filtrados'
        Properties.Alignment = taRightJustify
        Style.TransparentBorder = False
        TabOrder = 25
      end
      object Button26: TButton
        Left = 1009
        Top = 11
        Width = 75
        Height = 20
        Anchors = [akTop, akRight]
        Caption = 'bbdd Connect'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 26
        OnClick = Button26Click
      end
      object Button24: TButton
        Left = 498
        Top = 28
        Width = 126
        Height = 25
        Caption = 'Replan'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 27
        OnClick = Button24Click
      end
    end
  end
  object popNode: TPopupMenu
    Left = 1008
    Top = 268
    object MenuItem3: TMenuItem
      AutoCheck = True
      Caption = 'Activar / bloquear'
      Checked = True
      OnClick = MenuItem3Click
    end
    object LibreMovimiento1: TMenuItem
      AutoCheck = True
      Caption = 'Libre Movimiento'
      OnClick = LibreMovimiento1Click
    end
    object Resetduracinoriginal1: TMenuItem
      Caption = 'Restablecer duraci'#243'n original'
      OnClick = Resetduracinoriginal1Click
    end
    object CompactarOF1: TMenuItem
      Caption = 'Compactar OF'
      object odalaOF1: TMenuItem
        Tag = 1
        Caption = 'Toda la OF'
        OnClick = odalaOF1Click
      end
      object odalaOF2: TMenuItem
        Tag = 1
        Caption = 'Toda la OF con prioridad'
        HelpContext = 1
        OnClick = odalaOF1Click
      end
      object CompactarOFapartirdelNodo1: TMenuItem
        Caption = 'A partir del Nodo'
        OnClick = odalaOF1Click
      end
      object ApartirdelNodoconprioridad1: TMenuItem
        Caption = 'A partir del Nodo con prioridad'
        HelpContext = 1
        OnClick = odalaOF1Click
      end
    end
    object CompactarOT1: TMenuItem
      Caption = 'Compactar OT'
      object otalaOT1: TMenuItem
        Tag = 1
        Caption = 'Toda la OT'
        OnClick = otalaOT1Click
      end
      object odalaOTconprioridad1: TMenuItem
        Tag = 1
        Caption = 'Toda la OT con prioridad'
        HelpContext = 1
        OnClick = otalaOT1Click
      end
      object ApartirdelNodo1: TMenuItem
        Caption = 'A partir del Nodo'
        OnClick = otalaOT1Click
      end
      object ApartirdelNodoconprioridad2: TMenuItem
        Caption = 'A partir del Nodo con prioridad'
        HelpContext = 1
        OnClick = otalaOT1Click
      end
    end
    object ShiftRow2: TMenuItem
      Caption = 'ShiftRow'
      OnClick = ShiftRow2Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Color1: TMenuItem
      Caption = 'Color'
      object Colordelnode1: TMenuItem
        Caption = 'Color del node...'
        OnClick = Colordelnode1Click
      end
      object ColordelaOrdendetrabajo1: TMenuItem
        Tag = 1
        Caption = 'Color de la Orden de trabajo...'
        OnClick = Colordelnode1Click
      end
      object ColordelaOrdendeFabricacin1: TMenuItem
        Tag = 2
        Caption = 'Color de la Orden de Fabricaci'#243'n'
        OnClick = Colordelnode1Click
      end
      object ColordelPedido1: TMenuItem
        Tag = -1
        Caption = 'Color del Pedido...'
        Enabled = False
      end
      object ColordelProyecto1: TMenuItem
        Tag = -1
        Caption = 'Color del Proyecto...'
        Enabled = False
      end
    end
    object ResaltarOF1: TMenuItem
      Caption = 'Resaltar OF'
      OnClick = ResaltarOF1Click
    end
    object Info1: TMenuItem
      Caption = 'Info'
      OnClick = Info1Click
    end
  end
  object tmr1Sec: TTimer
    OnTimer = tmr1SecTimer
    Left = 704
    Top = 240
  end
  object MainMenu1: TMainMenu
    Left = 736
    Top = 368
    object Archivo1: TMenuItem
      Caption = 'Archivo'
      object N4: TMenuItem
        Caption = '-'
      end
      object Proyectos1: TMenuItem
        Caption = 'Proyectos...'
        OnClick = Proyectos1Click
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object Salir1: TMenuItem
        Caption = 'Salir'
        OnClick = Salir1Click
      end
    end
    object Entidades1: TMenuItem
      Caption = 'Entidades'
      object Centros1: TMenuItem
        Caption = 'Centros'
        OnClick = Centros1Click
      end
      object Operarios1: TMenuItem
        Caption = 'Operarios'
        OnClick = Operarios1Click
      end
      object Calendarios1: TMenuItem
        Caption = 'Calendarios'
        OnClick = Calendarios1Click
      end
      object Areas1: TMenuItem
        Caption = #193'reas'
        OnClick = Areas1Click
      end
      object Departamentos1: TMenuItem
        Caption = 'Departamentos'
        OnClick = Departamentos1Click
      end
      object Capacitaciones1: TMenuItem
        Caption = 'Capacitaciones'
        OnClick = Capacitaciones1Click
      end
      object Turnos1: TMenuItem
        Caption = 'Turnos'
        OnClick = Turnos1Click
      end
      object Moldes1: TMenuItem
        Caption = 'Moldes y utillajes'
        OnClick = Moldes1Click
      end
      object Utillajes1: TMenuItem
        Caption = 'Marcadores'
      end
      object Links1: TMenuItem
        Caption = 'Links'
        Enabled = False
      end
    end
    object Vistas1: TMenuItem
      Caption = 'Vistas'
      object Dashboard1: TMenuItem
        Caption = 'Dashboard'
        OnClick = Dashboard1Click
      end
      object MnGantt: TMenuItem
        Caption = 'Gantt'
        OnClick = MnGanttClick
      end
      object Kanban1: TMenuItem
        Caption = 'Kanban'
        OnClick = Kanban1Click
      end
      object DispatchList1: TMenuItem
        Caption = 'Lista de Prioridades'
        OnClick = DispatchList1Click
      end
      object Backlog1: TMenuItem
        Caption = 'Backlog / Carga pendiente'
        OnClick = Backlog1Click
      end
      object FiniteCapacity1: TMenuItem
        Caption = 'Planificador Capacidad Finita'
        OnClick = FiniteCapacity1Click
      end
      object CuadroPlanificacionDia1: TMenuItem
        Caption = 'Cuadro Planificaci'#243'n del D'#237'a'
        OnClick = CuadroPlanificacionDia1Click
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Indicadoresdecentros1: TMenuItem
        Caption = 'Indicadores de centros'
        OnClick = Indicadoresdecentros1Click
      end
    end
    object Configuracion1: TMenuItem
      Caption = 'Configuraci'#243'n'
      object Roles1: TMenuItem
        Caption = 'Roles y Permisos'
        OnClick = Roles1Click
      end
      object Usuarios1: TMenuItem
        Caption = 'Usuarios'
        OnClick = Usuarios1Click
      end
      object NDemo1: TMenuItem
        Caption = '-'
      end
      object InstalarDemos1: TMenuItem
        Caption = 'Instalar datos de Demo...'
        OnClick = InstalarDemos1Click
      end
      object ConfigEmpresa1: TMenuItem
        Caption = 'Configuraci'#243'n de Empresa...'
        OnClick = ConfigEmpresa1Click
      end
      object SelectorErp1: TMenuItem
        Caption = 'Selector de ERP...'
        OnClick = SelectorErp1Click
      end
      object AsistenteInstalacion1: TMenuItem
        Caption = 'Asistente de instalaci'#243'n...'
        OnClick = AsistenteInstalacion1Click
      end
      object GenerarNodosDemo1: TMenuItem
        Caption = 'Generar nodos demo...'
        OnClick = GenerarNodosDemo1Click
      end
      object GenerarBacklogDemo1: TMenuItem
        Caption = 'Generar Backlog demo...'
        OnClick = GenerarBacklogDemo1Click
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object CamposPersonalizados1: TMenuItem
        Caption = 'Campos Personalizados'
        OnClick = CamposPersonalizados1Click
      end
      object ReglasPlanificacion1: TMenuItem
        Caption = 'Reglas de Planificaci'#243'n'
        OnClick = ReglasPlanificacion1Click
      end
    end
    object Ayuda1: TMenuItem
      Caption = 'Ayuda'
      object Acercade1: TMenuItem
        Caption = 'Acerca de...'
      end
    end
  end
end
