object frmDashboard: TfrmDashboard
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Dashboard'
  ClientHeight = 784
  ClientWidth = 900
  Color = 15395562
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      900
      70)
    object lblTitulo: TLabel
      Left = 70
      Top = 5
      Width = 177
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
      Left = 70
      Top = 39
      Width = 148
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
      ParentFont = False
      Layout = tlCenter
    end
    object lblPendingSync: TLabel
      Left = 440
      Top = 4
      Width = 440
      Height = 20
      Cursor = crHandPoint
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'OF pendientes'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsUnderline]
      ParentFont = False
      Transparent = True
      Layout = tlCenter
      OnClick = lblPendingSyncClick
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
        4D31342032314331332E343437372032312031332032302E3535323320313320
        32305631324331332031312E343437372031332E343437372031312031342031
        314832304332302E353532332031312032312031312E34343737203231203132
        5632304332312032302E353532332032302E3535323320323120323020323148
        31345A4D3420313343332E343437373220313320332031322E35353233203320
        31325634433320332E343437373220332E343437373220332034203348313043
        31302E35353233203320313120332E3434373732203131203456313243313120
        31322E353532332031302E3535323320313320313020313348345A4D39203131
        5635483556313148395A4D3420323143332E343437373220323120332032302E
        35353233203320323056313643332031352E3434373720332E34343737322031
        3520342031354831304331302E353532332031352031312031352E3434373720
        31312031365632304331312032302E353532332031302E353532332032312031
        3020323148345A4D35203139483956313748355631395A4D3135203139483139
        5631334831355631395A4D3133203443313320332E34343737322031332E3434
        3737203320313420334832304332302E35353233203320323120332E34343737
        322032312034563843323120382E35353232382032302E353532332039203230
        20394831344331332E34343737203920313320382E3535323238203133203856
        345A4D31352035563748313956354831355A222F3E0D0A3C2F7376673E0D0A}
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Properties.ShowFocusRect = False
      Style.BorderStyle = ebsNone
      TabOrder = 0
      Transparent = True
      ExplicitTop = 12
      ExplicitHeight = 56
      Height = 52
      Width = 56
    end
  end
  object pnlCards: TPanel
    Left = 0
    Top = 70
    Width = 900
    Height = 714
    Align = alClient
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 1
    ExplicitTop = 80
    ExplicitHeight = 704
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
        Width = 48
        Height = 13
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
        Width = 95
        Height = 13
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
        Width = 47
        Height = 13
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
      Height = 150
      BevelOuter = bvNone
      Color = 15856098
      ParentBackground = False
      TabOrder = 3
      object lblMetricasCap: TLabel
        Left = 16
        Top = 14
        Width = 70
        Height = 13
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
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
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
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
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
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
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
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
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
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
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
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
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
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
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
      Top = 354
      Width = 872
      Height = 200
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 4
      object lblProyectoActivoCap: TLabel
        Left = 16
        Top = 14
        Width = 166
        Height = 13
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
      object lblCapOFsPendientes: TLabel
        Left = 480
        Top = 152
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'OF pendientes ERP:'
      end
      object lblValOFsPendientes: TLabel
        Left = 644
        Top = 152
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
      object lblCapOTsPendientes: TLabel
        Left = 480
        Top = 172
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'OT pendientes ERP:'
      end
      object lblValOTsPendientes: TLabel
        Left = 644
        Top = 172
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
      Top = 576
      Width = 872
      Height = 41
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 5
    end
  end
  object TimerReloj: TTimer
    OnTimer = TimerRelojTimer
    Left = 840
    Top = 96
  end
end
