object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'FS Planner 2026: Empresa Demo'
  ClientHeight = 540
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
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 1092
    Height = 33
    Align = alTop
    BevelOuter = bvNone
    Color = 14869218
    ParentBackground = False
    TabOrder = 0
    object btnTB_Dashboard: TcxButton
      AlignWithMargins = True
      Left = 6
      Top = 5
      Width = 75
      Height = 23
      Margins.Left = 6
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'Dashboard'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Down = True
      SpeedButtonOptions.Flat = True
      TabOrder = 0
      OnClick = Dashboard1Click
    end
    object btnTB_BackLog: TcxButton
      AlignWithMargins = True
      Left = 87
      Top = 5
      Width = 60
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'Data'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 1
      OnClick = Backlog1Click
    end
    object btnTB_PlaniCentros: TcxButton
      AlignWithMargins = True
      Left = 219
      Top = 5
      Width = 75
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'Centros'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 2
      OnClick = FiniteCapacity1Click
      ExplicitLeft = 249
    end
    object cxButton1: TcxButton
      AlignWithMargins = True
      Left = 586
      Top = 5
      Width = 75
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'mas...'
      Enabled = False
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 3
      ExplicitLeft = 631
    end
    object btnTB_PlaniOperarios: TcxButton
      AlignWithMargins = True
      Left = 300
      Top = 5
      Width = 75
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'Operarios'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 4
      OnClick = FiniteCapacityOperaris1Click
      ExplicitLeft = 330
    end
    object btnTB_PlaniGantt: TcxButton
      AlignWithMargins = True
      Left = 381
      Top = 5
      Width = 60
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'Gantt'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2007Blue'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 5
      OnClick = MnGanttClick
    end
    object btnTB_Help: TcxButton
      AlignWithMargins = True
      Left = 961
      Top = 6
      Width = 25
      Height = 21
      Margins.Top = 6
      Margins.Bottom = 6
      Align = alRight
      Caption = '?'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 6
      OnClick = btnTB_HelpClick
    end
    object btnLinkERP: TcxButton
      AlignWithMargins = True
      Left = 1036
      Top = 6
      Width = 48
      Height = 21
      Margins.Top = 6
      Margins.Right = 8
      Margins.Bottom = 6
      Align = alRight
      Caption = 'Sage200'
      LookAndFeel.Kind = lfUltraFlat
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'DevExpressDarkStyle'
      SpeedButtonOptions.CanBeFocused = False
      TabOrder = 7
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnLinkERPClick
    end
    object btnTB_Demo: TcxButton
      AlignWithMargins = True
      Left = 992
      Top = 6
      Width = 37
      Height = 21
      Margins.Top = 6
      Margins.Right = 4
      Margins.Bottom = 6
      Align = alRight
      Caption = 'Demo'
      LookAndFeel.Kind = lfUltraFlat
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 2
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.AllowAllUp = True
      TabOrder = 10
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnTB_DemoClick
    end
    object cxButton2: TcxButton
      AlignWithMargins = True
      Left = 153
      Top = 5
      Width = 60
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'MRP'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 8
      OnClick = cxButton2Click
    end
    object btnTB_PlaniAlertas: TcxButton
      AlignWithMargins = True
      Left = 447
      Top = 5
      Width = 133
      Height = 23
      Margins.Top = 5
      Margins.Bottom = 5
      Align = alLeft
      Caption = 'Alertas (12)'
      Colors.Default = 8421631
      Colors.Normal = 8421631
      LookAndFeel.Kind = lfUltraFlat
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2007Pink'
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 9
      OnClick = btnTB_PlaniAlertasClick
      ExplicitLeft = 492
    end
  end
  object tmr1Sec: TTimer
    OnTimer = tmr1SecTimer
    Left = 720
    Top = 128
  end
  object MainMenu1: TMainMenu
    Left = 816
    Top = 112
    object Archivo1: TMenuItem
      Caption = 'Archivo'
      object N4: TMenuItem
        Caption = '-'
      end
      object Proyectos1: TMenuItem
        Caption = 'Proyectos...'
        OnClick = Proyectos1Click
      end
      object PuntosRestauracion1: TMenuItem
        Caption = 'Puntos de restauraci'#243'n...'
        OnClick = PuntosRestauracion1Click
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
      object Maquinas1: TMenuItem
        Caption = 'M'#225'quinas'
        OnClick = Maquinas1Click
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
      object Ausencias1: TMenuItem
        Caption = 'Ausencias'
        OnClick = Ausencias1Click
      end
      object Habilidades1: TMenuItem
        Caption = 'Habilidades (cat'#225'logo)'
        OnClick = Habilidades1Click
      end
      object OperationTypes1: TMenuItem
        Caption = 'Tipos de operaci'#243'n (paralelismo)'
        OnClick = OperationTypes1Click
      end
      object OperacionHabilidades1: TMenuItem
        Caption = 'Operaciones - Habilidades requeridas'
        OnClick = OperacionHabilidades1Click
      end
      object PesosScoring1: TMenuItem
        Caption = 'Pesos de scoring...'
        OnClick = PesosScoring1Click
      end
      object Turnos1: TMenuItem
        Caption = 'Turnos'
        OnClick = Turnos1Click
      end
      object Moldes1: TMenuItem
        Caption = 'Moldes'
        OnClick = Moldes1Click
      end
      object Utillajes1: TMenuItem
        Caption = 'Utillajes'
        OnClick = Utillajes1Click
      end
      object Alertas1: TMenuItem
        Caption = 'Alertas (configuraci'#243'n)'
        OnClick = Alertas1Click
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
      object FiniteCapacityOperaris1: TMenuItem
        Caption = 'Planificador Capacidad por Operario'
        OnClick = FiniteCapacityOperaris1Click
      end
      object AutoPlanificacion1: TMenuItem
        Caption = 'Auto-planificaci'#243'n (scoring)...'
        OnClick = AutoPlanificacion1Click
      end
      object PlanificacionReglas1: TMenuItem
        Caption = 'Planificaci'#243'n por reglas...'
        OnClick = PlanificacionReglas1Click
      end
      object N2: TMenuItem
        Caption = '-'
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
      object PreferenciasGantt1: TMenuItem
        Caption = 'Preferencias del Gantt...'
        OnClick = PreferenciasGantt1Click
      end
      object SelectorErp1: TMenuItem
        Caption = 'Selector de ERP...'
        OnClick = SelectorErp1Click
      end
      object SincronizarERP1: TMenuItem
        Caption = 'Sincronizar con ERP...'
        OnClick = SincronizarERP1Click
      end
      object AsistenteInstalacion1: TMenuItem
        Caption = 'Asistente de instalaci'#243'n...'
        OnClick = AsistenteInstalacion1Click
      end
      object GenerarNodosDemo1: TMenuItem
        Caption = 'Generar nodos demo...'
        OnClick = GenerarNodosDemo1Click
      end
      object RegenerarGanttDemo1: TMenuItem
        Caption = 'Regenerar Gantt demo (modo demostraci'#243'n)...'
        OnClick = RegenerarGanttDemo1Click
      end
      object GenerarBacklogDemo1: TMenuItem
        Caption = 'Generar Backlog demo...'
        OnClick = GenerarBacklogDemo1Click
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object CamposPersonalizados1: TMenuItem
        Caption = 'Campos de nodos (reglas/cards)'
        OnClick = CamposPersonalizados1Click
      end
      object ColumnasPersonalizadas1: TMenuItem
        Caption = 'Columnas personalizadas'
        OnClick = ColumnasPersonalizadas1Click
      end
      object ReglasPlanificacion1: TMenuItem
        Caption = 'Reglas de Planificaci'#243'n'
        OnClick = ReglasPlanificacion1Click
      end
      object NCards1: TMenuItem
        Caption = '-'
      end
      object GestionCardLayouts1: TMenuItem
        Caption = 'Gesti'#243'n de Card Layouts'
        OnClick = GestionCardLayouts1Click
      end
      object DisenadorNodos1: TMenuItem
        Caption = 'Dise'#241'ador de Nodos del Gantt'
        OnClick = DisenadorNodos1Click
      end
      object ConfigHint1: TMenuItem
        Caption = 'Configurar informaci'#243'n emergente (hint)'
        OnClick = ConfigHint1Click
      end
    end
    object Funcionalidades1: TMenuItem
      Caption = 'An'#225'lisis'
      object DashboardOperativo1: TMenuItem
        Caption = 'Dashboard general...'
        OnClick = DashboardOperativo1Click
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object StockCockpit1: TMenuItem
        Caption = 'An'#225'lisis de stock...'
        OnClick = StockCockpit1Click
      end
      object ArticleDetail1: TMenuItem
        Caption = 'An'#225'lisis de art'#237'culo...'
        OnClick = ArticleDetail1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object HeatmapCargaCentro1: TMenuItem
        Caption = 'Heatmap carga por centro'
        OnClick = HeatmapCargaCentro1Click
      end
      object HeatmapCargaOperario1: TMenuItem
        Caption = 'Heatmap carga por operario'
        OnClick = HeatmapCargaOperario1Click
      end
      object HeatmapEntregasVsCarga1: TMenuItem
        Caption = 'Heatmap entregas vs capacidad'
        OnClick = HeatmapEntregasVsCarga1Click
      end
      object HistogramasOperarios1: TMenuItem
        Caption = 'Histogramas de operarios'
        OnClick = HistogramasOperarios1Click
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object AnalisisPlan1: TMenuItem
        Caption = 'An'#225'lisis del plan'
        OnClick = AnalisisPlan1Click
      end
      object CuadroPlanificacionDia1: TMenuItem
        Caption = 'Cuadro Planificaci'#243'n del D'#237'a'
        OnClick = CuadroPlanificacionDia1Click
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object AlertasPlanificacion1: TMenuItem
        Caption = 'Alertas de planificaci'#243'n...'
        OnClick = AlertasPlanificacion1Click
      end
      object Indicadoresdecentros1: TMenuItem
        Caption = 'Indicadores de centros'
        OnClick = Indicadoresdecentros1Click
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
