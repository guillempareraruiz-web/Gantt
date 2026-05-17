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
      object FiniteCapacityOperaris1: TMenuItem
        Caption = 'Planificador Capacidad por Operario'
        OnClick = FiniteCapacityOperaris1Click
      end
      object AutoPlanificacion1: TMenuItem
        Caption = 'Auto-planificaci'#243'n (scoring)...'
        OnClick = AutoPlanificacion1Click
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
    end
    object Ayuda1: TMenuItem
      Caption = 'Ayuda'
      object Acercade1: TMenuItem
        Caption = 'Acerca de...'
      end
    end
  end
end
