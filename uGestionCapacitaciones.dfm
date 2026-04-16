object frmGestionCapacitaciones: TfrmGestionCapacitaciones
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de Capacitaciones'
  ClientHeight = 520
  ClientWidth = 900
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object splMain: TSplitter
    Left = 320
    Top = 60
    Width = 4
    Height = 420
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 128
      Height = 25
      Caption = 'Capacitaciones'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 36
      Width = 315
      Height = 15
      Caption = 'Operaciones que cada operario est'#225' capacitado para realizar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 480
    Width = 900
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 792
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 60
    Width = 320
    Height = 420
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 2
    object lblOperarios: TLabel
      Left = 12
      Top = 8
      Width = 58
      Height = 13
      Caption = 'OPERARIOS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object gridOperarios: TcxGrid
      Left = 8
      Top = 28
      Width = 304
      Height = 384
      TabOrder = 0
      object tvOperarios: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        OnFocusedRecordChanged = tvOperariosFocusedRecordChanged
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
        object colOpId: TcxGridColumn
          Caption = 'ID'
          Width = 50
        end
        object colOpNombre: TcxGridColumn
          Caption = 'Nombre'
          Width = 200
        end
        object colOpSkillsCount: TcxGridColumn
          Caption = 'Skills'
          Width = 50
        end
      end
      object lvOperarios: TcxGridLevel
        GridView = tvOperarios
      end
    end
  end
  object pnlRight: TPanel
    Left = 324
    Top = 60
    Width = 576
    Height = 420
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object lblSkills: TLabel
      Left = 12
      Top = 8
      Width = 163
      Height = 13
      Caption = 'CAPACITACIONES DEL OPERARIO'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object pnlSkillToolbar: TPanel
      Left = 8
      Top = 28
      Width = 560
      Height = 36
      BevelOuter = bvNone
      TabOrder = 0
      object lblNuevaSkill: TLabel
        Left = 0
        Top = 10
        Width = 60
        Height = 15
        Caption = 'Nueva skill:'
      end
      object cmbNuevaSkill: TComboBox
        Left = 88
        Top = 6
        Width = 240
        Height = 23
        TabOrder = 0
      end
      object btnAddSkill: TButton
        Left = 336
        Top = 4
        Width = 100
        Height = 28
        Caption = 'A'#241'adir'
        TabOrder = 1
        OnClick = btnAddSkillClick
      end
      object btnDelSkill: TButton
        Left = 444
        Top = 4
        Width = 100
        Height = 28
        Caption = 'Eliminar'
        TabOrder = 2
        OnClick = btnDelSkillClick
      end
    end
    object gridSkills: TcxGrid
      Left = 8
      Top = 72
      Width = 560
      Height = 340
      TabOrder = 1
      object tvSkills: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
        object colSkillOperacion: TcxGridColumn
          Caption = 'Operaci'#243'n'
          Width = 400
        end
      end
      object lvSkills: TcxGridLevel
        GridView = tvSkills
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 840
    Top = 12
  end
end
