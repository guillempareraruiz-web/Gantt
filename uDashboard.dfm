object frmDashboard: TfrmDashboard
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Dashboard'
  ClientHeight = 720
  ClientWidth = 900
  Color = 15395562
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 24
      Top = 16
      Width = 200
      Height = 32
      Caption = 'Panel de control'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 24
      Top = 52
      Width = 200
      Height = 15
      Caption = 'Resumen de la sesi'#243'n actual'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblFechaHora: TLabel
      Left = 640
      Top = 28
      Width = 240
      Height = 28
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = '--/--/---- --:--'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = []
      Layout = tlCenter
      ParentFont = False
    end
  end
  object pnlCards: TPanel
    Left = 0
    Top = 80
    Width = 900
    Height = 640
    Align = alClient
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 1
    object pnlEmpresa: TPanel
      Left = 24
      Top = 24
      Width = 280
      Height = 140
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblEmpresaCap: TLabel
        Left = 16
        Top = 14
        Width = 56
        Height = 15
        Caption = 'EMPRESA'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblEmpresaNombre: TLabel
        Left = 16
        Top = 40
        Width = 248
        Height = 25
        AutoSize = False
        Caption = '--'
        EllipsisPosition = epEndEllipsis
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -19
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblEmpresaCodigo: TLabel
        Left = 16
        Top = 72
        Width = 248
        Height = 15
        AutoSize = False
        Caption = 'C'#243'digo: --'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlProyecto: TPanel
      Left = 320
      Top = 24
      Width = 280
      Height = 140
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblProyectoCap: TLabel
        Left = 16
        Top = 14
        Width = 100
        Height = 15
        Caption = 'PROYECTO ACTIVO'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblProyectoNombre: TLabel
        Left = 16
        Top = 40
        Width = 248
        Height = 25
        AutoSize = False
        Caption = '--'
        EllipsisPosition = epEndEllipsis
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -19
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblProyectoTipo: TLabel
        Left = 16
        Top = 72
        Width = 248
        Height = 15
        AutoSize = False
        Caption = 'Tipo: --'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlUsuario: TPanel
      Left = 616
      Top = 24
      Width = 280
      Height = 140
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 2
      object lblUsuarioCap: TLabel
        Left = 16
        Top = 14
        Width = 48
        Height = 15
        Caption = 'USUARIO'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblUsuarioNombre: TLabel
        Left = 16
        Top = 40
        Width = 248
        Height = 25
        AutoSize = False
        Caption = '--'
        EllipsisPosition = epEndEllipsis
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -19
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblUsuarioRol: TLabel
        Left = 16
        Top = 72
        Width = 248
        Height = 15
        AutoSize = False
        Caption = 'Rol: --'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlMetricas: TPanel
      Left = 24
      Top = 184
      Width = 872
      Height = 140
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 3
      object lblMetricasCap: TLabel
        Left = 16
        Top = 14
        Width = 60
        Height = 15
        Caption = 'CONTADORES'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblCapCalendarios: TLabel
        Left = 16
        Top = 44
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Calendarios:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValCalendarios: TLabel
        Left = 160
        Top = 44
        Width = 80
        Height = 17
        AutoSize = False
        Caption = '0'
        Cursor = crHandPoint
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValCalendariosClick
      end
      object lblCapCentros: TLabel
        Left = 16
        Top = 68
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Centros:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValCentros: TLabel
        Left = 160
        Top = 68
        Width = 80
        Height = 17
        AutoSize = False
        Caption = '0'
        Cursor = crHandPoint
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValCentrosClick
      end
      object lblCapAreas: TLabel
        Left = 16
        Top = 92
        Width = 140
        Height = 17
        AutoSize = False
        Caption = #193'reas:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValAreas: TLabel
        Left = 160
        Top = 92
        Width = 80
        Height = 17
        AutoSize = False
        Caption = '0'
        Cursor = crHandPoint
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValAreasClick
      end
      object lblCapTurnos: TLabel
        Left = 260
        Top = 44
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Turnos:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValTurnos: TLabel
        Left = 404
        Top = 44
        Width = 80
        Height = 17
        AutoSize = False
        Caption = '0'
        Cursor = crHandPoint
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValTurnosClick
      end
      object lblCapCapacitaciones: TLabel
        Left = 260
        Top = 68
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Capacitaciones:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValCapacitaciones: TLabel
        Left = 404
        Top = 68
        Width = 80
        Height = 17
        AutoSize = False
        Caption = '0'
        Cursor = crHandPoint
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValCapacitacionesClick
      end
      object lblCapOperarios: TLabel
        Left = 260
        Top = 92
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Operarios:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValOperarios: TLabel
        Left = 404
        Top = 92
        Width = 80
        Height = 17
        AutoSize = False
        Caption = '0'
        Cursor = crHandPoint
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValOperariosClick
      end
      object lblCapDepartamentos: TLabel
        Left = 16
        Top = 116
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Departamentos:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValDepartamentos: TLabel
        Left = 160
        Top = 116
        Width = 80
        Height = 17
        AutoSize = False
        Caption = '0'
        Cursor = crHandPoint
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValDepartamentosClick
      end
    end
    object pnlProyectoActivo: TPanel
      Left = 24
      Top = 340
      Width = 872
      Height = 200
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 4
      object lblProyectoActivoCap: TLabel
        Left = 16
        Top = 14
        Width = 200
        Height = 15
        Caption = 'PROYECTO ACTIVO PLANIFICADO'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblCapFechaInicio: TLabel
        Left = 16
        Top = 44
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Fecha inicio:'
      end
      object lblValFechaInicio: TLabel
        Left = 160
        Top = 44
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapFechaFin: TLabel
        Left = 16
        Top = 64
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Fecha fin:'
      end
      object lblValFechaFin: TLabel
        Left = 160
        Top = 64
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapFechaBloqueo: TLabel
        Left = 16
        Top = 84
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Fecha bloqueo:'
      end
      object lblValFechaBloqueo: TLabel
        Left = 160
        Top = 84
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapNodos: TLabel
        Left = 16
        Top = 108
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Nodos planificados:'
      end
      object lblValNodos: TLabel
        Left = 160
        Top = 108
        Width = 300
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapOFs: TLabel
        Left = 16
        Top = 128
        Width = 140
        Height = 17
        AutoSize = False
        Caption = #211'rdenes de fabricaci'#243'n:'
      end
      object lblValOFs: TLabel
        Left = 160
        Top = 128
        Width = 300
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapPedidos: TLabel
        Left = 16
        Top = 148
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Pedidos:'
      end
      object lblValPedidos: TLabel
        Left = 160
        Top = 148
        Width = 300
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapCentrosUsados: TLabel
        Left = 480
        Top = 44
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Centros utilizados:'
      end
      object lblValCentrosUsados: TLabel
        Left = 644
        Top = 44
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapOperariosAsignados: TLabel
        Left = 480
        Top = 64
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Operarios asignados:'
      end
      object lblValOperariosAsignados: TLabel
        Left = 644
        Top = 64
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapDuracionTotal: TLabel
        Left = 480
        Top = 92
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Duraci'#243'n total planificada:'
      end
      object lblValDuracionTotal: TLabel
        Left = 644
        Top = 92
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapDependencias: TLabel
        Left = 480
        Top = 112
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Dependencias:'
      end
      object lblCapMarcadores: TLabel
        Left = 480
        Top = 132
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Marcadores:'
      end
      object lblValMarcadores: TLabel
        Left = 644
        Top = 132
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblValDependencias: TLabel
        Left = 644
        Top = 112
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object pnlAcciones: TPanel
      Left = 24
      Top = 560
      Width = 872
      Height = 60
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 5
      object btnAbrirGantt: TButton
        Left = 16
        Top = 14
        Width = 200
        Height = 32
        Caption = 'Abrir planificaci'#243'n (Gantt)'
        TabOrder = 0
        OnClick = btnAbrirGanttClick
      end
    end
  end
  object TimerReloj: TTimer
    Interval = 1000
    OnTimer = TimerRelojTimer
    Left = 840
    Top = 96
  end
end
