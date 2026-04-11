object frmNodeInspector: TfrmNodeInspector
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Node Inspector'
  ClientHeight = 680
  ClientWidth = 520
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 520
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      520
      60)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 490
      Height = 22
      AutoSize = False
      Caption = 'Node Inspector'
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
      Width = 490
      Height = 18
      AutoSize = False
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
      Width = 520
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
      ExplicitTop = 57
    end
    object chkDarkMode: TCheckBox
      Left = 430
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
    Top = 640
    Width = 520
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      520
      40)
    object btnOK: TButton
      Left = 340
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 430
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object pcMain: TPageControl
    Left = 0
    Top = 60
    Width = 520
    Height = 580
    ActivePage = tabGeneral
    Align = alClient
    TabOrder = 1
    object tabGeneral: TTabSheet
      Caption = 'General'
      object vg: TcxVerticalGrid
        Left = 0
        Top = 0
        Width = 512
        Height = 550
        Align = alClient
        OptionsView.RowHeaderWidth = 180
        OptionsView.ValueWidth = 300
        OptionsBehavior.AlwaysShowEditor = True
        TabOrder = 0
        Version = 1
      end
    end
    object tabCustomFields: TTabSheet
      Caption = 'Campos Personalizados'
      ImageIndex = 1
      object pnlCustomTop: TPanel
        Left = 0
        Top = 0
        Width = 512
        Height = 32
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object btnEditFields: TButton
          Left = 4
          Top = 3
          Width = 140
          Height = 25
          Caption = 'Editar campos...'
          TabOrder = 0
          OnClick = btnEditFieldsClick
        end
      end
      object vgCustom: TcxVerticalGrid
        Left = 0
        Top = 32
        Width = 512
        Height = 518
        Align = alClient
        OptionsView.RowHeaderWidth = 180
        OptionsView.ValueWidth = 300
        OptionsBehavior.AlwaysShowEditor = True
        TabOrder = 0
        Version = 1
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 248
    Top = 320
  end
end
