object frmGestionCalendarios: TfrmGestionCalendarios
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Gesti'#243'n de Calendarios'
  ClientHeight = 700
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object splMain: TSplitter
    Left = 260
    Top = 60
    Width = 6
    Height = 600
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1100
      60)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 700
      Height = 22
      AutoSize = False
      Caption = 'Gesti'#243'n de Calendarios'
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 33
      Width = 700
      Height = 18
      AutoSize = False
      Caption = 'Visualizaci'#243'n anual de d'#237'as laborables, festivos y horarios'
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object shpHeaderLine: TShape
      Left = 0
      Top = 58
      Width = 1100
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
    end
    object chkDarkMode: TCheckBox
      Left = 1010
      Top = 8
      Width = 80
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'Oscuro'
      TabOrder = 0
      OnClick = chkDarkModeClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 660
    Width = 1100
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      1100
      40)
    object btnCerrar: TButton
      Left = 1010
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 60
    Width = 260
    Height = 600
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object lblCalendarios: TLabel
      Left = 8
      Top = 4
      Width = 70
      Height = 17
      Caption = 'Calendarios'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lbCalendarios: TListBox
      Left = 0
      Top = 24
      Width = 260
      Height = 304
      Align = alClient
      ItemHeight = 15
      TabOrder = 0
      OnClick = lbCalendariosClick
    end
    object pnlCalToolbar: TPanel
      Left = 0
      Top = 328
      Width = 260
      Height = 36
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object btnCalAdd: TButton
        Left = 4
        Top = 4
        Width = 75
        Height = 28
        Caption = 'A'#241'adir'
        TabOrder = 0
        OnClick = btnCalAddClick
      end
      object btnCalEdit: TButton
        Left = 83
        Top = 4
        Width = 75
        Height = 28
        Caption = 'Editar'
        TabOrder = 1
        OnClick = btnCalEditClick
      end
      object btnCalDel: TButton
        Left = 162
        Top = 4
        Width = 75
        Height = 28
        Caption = 'Eliminar'
        TabOrder = 2
        OnClick = btnCalDelClick
      end
    end
    object pnlDetalle: TPanel
      Left = 0
      Top = 364
      Width = 260
      Height = 236
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object lblDetalleTitulo: TLabel
        Left = 8
        Top = 4
        Width = 129
        Height = 17
        Caption = 'Detalle del calendario'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4474440
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object memoDetalle: TMemo
        Left = 0
        Top = 26
        Width = 260
        Height = 204
        Align = alBottom
        Anchors = [akLeft, akTop, akRight, akBottom]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object pnlRight: TPanel
    Left = 266
    Top = 60
    Width = 834
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object lblAnioCaption: TLabel
      Left = 8
      Top = 4
      Width = 68
      Height = 17
      Caption = 'Vista Anual'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object pbCalendar: TPaintBox
      Left = 0
      Top = 0
      Width = 834
      Height = 568
      Align = alClient
      OnMouseMove = pbCalendarMouseMove
      OnPaint = pbCalendarPaint
      ExplicitTop = 26
      ExplicitHeight = 542
    end
    object pnlLeyenda: TPanel
      Left = 0
      Top = 568
      Width = 834
      Height = 32
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 550
    Top = 350
  end
end
