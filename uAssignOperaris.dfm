object frmAssignOperaris: TfrmAssignOperaris
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Assignar Operaris'
  ClientHeight = 557
  ClientWidth = 787
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
    Width = 787
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 780
    DesignSize = (
      787
      60)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 600
      Height = 22
      AutoSize = False
      Caption = 'Assignar Operaris'
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
      Width = 600
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
      Width = 787
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
      ExplicitWidth = 780
    end
    object chkDarkMode: TCheckBox
      Left = 697
      Top = 8
      Width = 80
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'Oscuro'
      TabOrder = 0
      OnClick = chkDarkModeClick
      ExplicitLeft = 690
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 517
    Width = 787
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 520
    ExplicitWidth = 780
    DesignSize = (
      787
      40)
    object lblResumen: TLabel
      Left = 16
      Top = 10
      Width = 400
      Height = 18
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnOK: TButton
      Left = 607
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Acceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
      ExplicitLeft = 600
    end
    object btnCancel: TButton
      Left = 697
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'#183'lar'
      TabOrder = 1
      OnClick = btnCancelClick
      ExplicitLeft = 690
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 60
    Width = 787
    Height = 457
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 780
    ExplicitHeight = 460
    object splCenter: TSplitter
      Left = 359
      Top = 0
      Width = 62
      Height = 457
      Beveled = True
      ResizeStyle = rsUpdate
      ExplicitHeight = 460
    end
    object pnlAssignats: TPanel
      Left = 0
      Top = 0
      Width = 359
      Height = 457
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitHeight = 460
      object lblAssignats: TLabel
        Left = 8
        Top = 4
        Width = 113
        Height = 17
        Caption = 'Operaris Assignats'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4474440
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object gridAssignats: TcxGrid
        Left = 0
        Top = 26
        Width = 359
        Height = 431
        Align = alBottom
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabOrder = 0
        ExplicitHeight = 434
        object tvAssignats: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Inserting = False
          OptionsSelection.MultiSelect = True
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colAsigId: TcxGridColumn
            Caption = 'ID'
            Options.Editing = False
            Width = 40
          end
          object colAsigNombre: TcxGridColumn
            Caption = 'Operari'
            Options.Editing = False
            Width = 160
          end
          object colAsigHoras: TcxGridColumn
            Caption = 'Hores'
            PropertiesClassName = 'TcxSpinEditProperties'
            Width = 70
          end
          object colAsigCapacitats: TcxGridColumn
            Caption = 'Capacitacions'
            Options.Editing = False
            Width = 120
          end
        end
        object lvAssignats: TcxGridLevel
          GridView = tvAssignats
        end
      end
    end
    object pnlDisponibles: TPanel
      Left = 421
      Top = 0
      Width = 366
      Height = 457
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitWidth = 359
      ExplicitHeight = 460
      object lblDisponibles: TLabel
        Left = 8
        Top = 4
        Width = 124
        Height = 17
        Caption = 'Operaris Disponibles'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4474440
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object gridDisponibles: TcxGrid
        Left = 0
        Top = 26
        Width = 366
        Height = 431
        Align = alBottom
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabOrder = 0
        ExplicitWidth = 359
        ExplicitHeight = 434
        object tvDisponibles: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.MultiSelect = True
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colDispId: TcxGridColumn
            Caption = 'ID'
            Width = 40
          end
          object colDispNombre: TcxGridColumn
            Caption = 'Operari'
            Width = 160
          end
          object colDispCalendario: TcxGridColumn
            Caption = 'Calendari'
            Width = 70
          end
          object colDispCapacitats: TcxGridColumn
            Caption = 'Capacitacions'
            Width = 120
          end
        end
        object lvDisponibles: TcxGridLevel
          GridView = tvDisponibles
        end
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 392
    Top = 280
  end
end
