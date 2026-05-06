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
  PixelsPerInch = 96
  TextHeight = 15
  object pnlOldGantt: TPanel
    Left = 56
    Top = 76
    Width = 833
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
      Left = 273
      Top = 120
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
      Width = 831
      Height = 113
      Align = alTop
      Color = 15395562
      ParentBackground = False
      TabOrder = 2
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
      object spCentros: TcxSpinEdit
        Left = 288
        Top = 31
        Properties.AssignedValues.MinValue = True
        Properties.ImmediatePost = True
        TabOrder = 0
        Value = 3
        Width = 57
      end
      object cxSpinEdit2: TcxSpinEdit
        Left = 351
        Top = 31
        Properties.AssignedValues.MinValue = True
        Properties.ImmediatePost = True
        TabOrder = 1
        Value = 30
        Width = 66
      end
      object Button6: TButton
        Left = 423
        Top = 29
        Width = 75
        Height = 25
        Caption = 'Recrear Raw'
        TabOrder = 2
        OnClick = Button6Click
      end
    end
  end
  object popNode: TPopupMenu
    Left = 968
    Top = 12
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
  end
  object tmr1Sec: TTimer
    OnTimer = tmr1SecTimer
    Left = 760
    Top = 8
  end
  object MainMenu1: TMainMenu
    Left = 864
    Top = 8
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
