object frmDashboard: TfrmDashboard
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Dashboard'
  ClientHeight = 500
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
    Height = 420
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
    object pnlAcciones: TPanel
      Left = 24
      Top = 184
      Width = 872
      Height = 80
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 3
      object btnAbrirGantt: TButton
        Left = 16
        Top = 24
        Width = 200
        Height = 36
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
