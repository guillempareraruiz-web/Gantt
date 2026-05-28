object frmGestionCalendarios: TfrmGestionCalendarios
  Left = 0
  Top = 0
  BorderStyle = bsDialog
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
    Left = 180
    Top = 60
    Width = 6
    Height = 640
    ExplicitHeight = 600
  end
  object splModels: TSplitter
    Left = 386
    Top = 60
    Width = 6
    Height = 640
    ExplicitHeight = 600
  end
  object splDetalle: TSplitter
    Left = 804
    Top = 60
    Width = 6
    Height = 640
    Align = alRight
    Visible = False
    ExplicitHeight = 600
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
    object chkVerIndicadores: TCheckBox
      Left = 1002
      Top = 20
      Width = 120
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Ver indicadores'
      TabOrder = 0
      OnClick = chkVerIndicadoresClick
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 60
    Width = 180
    Height = 640
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitHeight = 600
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
      Top = 0
      Width = 180
      Height = 570
      Align = alClient
      ItemHeight = 15
      TabOrder = 0
      OnClick = lbCalendariosClick
      ExplicitHeight = 530
    end
    object pnlCalToolbar: TPanel
      Left = 0
      Top = 570
      Width = 180
      Height = 70
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitTop = 530
      object btnCalAdd: TButton
        Left = 4
        Top = 4
        Width = 54
        Height = 28
        Caption = 'A'#241'adir'
        TabOrder = 0
        OnClick = btnCalAddClick
      end
      object btnCalEdit: TButton
        Left = 62
        Top = 4
        Width = 54
        Height = 28
        Caption = 'Editar'
        TabOrder = 1
        OnClick = btnCalEditClick
      end
      object btnCalDel: TButton
        Left = 120
        Top = 4
        Width = 56
        Height = 28
        Caption = 'Eliminar'
        TabOrder = 2
        OnClick = btnCalDelClick
      end
      object btnCalClone: TButton
        Left = 4
        Top = 38
        Width = 172
        Height = 28
        Caption = 'Clonar...'
        TabOrder = 3
        OnClick = btnCalCloneClick
      end
    end
  end
  object pnlDetalle: TPanel
    Left = 810
    Top = 60
    Width = 290
    Height = 640
    Align = alRight
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 4
    Visible = False
    ExplicitHeight = 600
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
    object sbDetalle: TScrollBox
      Left = 0
      Top = 0
      Width = 290
      Height = 640
      Align = alClient
      BorderStyle = bsNone
      Color = clWhite
      ParentColor = False
      TabOrder = 0
      ExplicitHeight = 600
      object pbDetalle: TPaintBox
        Left = 0
        Top = 0
        Width = 273
        Height = 800
        Align = alTop
        OnPaint = pbDetallePaint
        ExplicitWidth = 290
      end
    end
  end
  object pnlModels: TPanel
    Left = 186
    Top = 60
    Width = 200
    Height = 640
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitHeight = 600
    object lblModelos: TLabel
      Left = 8
      Top = 4
      Width = 106
      Height = 17
      Caption = 'Modelos horarios'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblModelosHint: TLabel
      Left = 8
      Top = 22
      Width = 184
      Height = 30
      AutoSize = False
      Caption = 
        'Plantillas horarias que definen las franjas laborables del calen' +
        'dario.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lbModelos: TListBox
      Left = 0
      Top = 0
      Width = 200
      Height = 498
      Align = alClient
      ItemHeight = 15
      TabOrder = 0
      OnClick = lbModelosClick
      OnDblClick = lbModelosDblClick
      ExplicitHeight = 458
    end
    object pnlModelosToolbar: TPanel
      Left = 0
      Top = 498
      Width = 200
      Height = 142
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitTop = 458
      object btnModeloAdd: TButton
        Left = 4
        Top = 4
        Width = 60
        Height = 28
        Caption = 'A'#241'adir'
        TabOrder = 0
        OnClick = btnModeloAddClick
      end
      object btnModeloEdit: TButton
        Left = 68
        Top = 4
        Width = 60
        Height = 28
        Caption = 'Editar'
        TabOrder = 1
        OnClick = btnModeloEditClick
      end
      object btnModeloDel: TButton
        Left = 132
        Top = 4
        Width = 64
        Height = 28
        Caption = 'Eliminar'
        TabOrder = 2
        OnClick = btnModeloDelClick
      end
      object btnExcepciones: TButton
        Left = 4
        Top = 40
        Width = 192
        Height = 28
        Caption = 'Excepciones...'
        TabOrder = 3
        OnClick = btnExcepcionesClick
      end
      object btnImportFestivos: TButton
        Left = 4
        Top = 74
        Width = 192
        Height = 28
        Caption = 'Importar festivos...'
        TabOrder = 4
        OnClick = btnImportFestivosClick
      end
      object btnExcRecurrente: TButton
        Left = 4
        Top = 108
        Width = 192
        Height = 28
        Caption = 'Excepci'#243'n recurrente...'
        TabOrder = 5
        OnClick = btnExcRecurrenteClick
      end
    end
  end
  object pnlRight: TPanel
    Left = 392
    Top = 60
    Width = 412
    Height = 640
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitHeight = 600
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
      Width = 412
      Height = 608
      Align = alClient
      OnDblClick = pbCalendarDblClick
      OnMouseMove = pbCalendarMouseMove
      OnPaint = pbCalendarPaint
      ExplicitHeight = 568
    end
    object pnlLeyenda: TPanel
      Left = 0
      Top = 608
      Width = 412
      Height = 32
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitTop = 568
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 550
    Top = 350
  end
end
