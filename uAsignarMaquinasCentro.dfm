object frmAsignarMaquinasCentro: TfrmAsignarMaquinasCentro
  Left = 0
  Top = 0
  Caption = 'Asignar m'#225'quinas al centro'
  ClientHeight = 480
  ClientWidth = 600
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 162
      Height = 25
      Caption = 'Asignar m'#225'quinas'
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
      Width = 180
      Height = 15
      Caption = 'Marca las m'#225'quinas de este centro'
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
    Top = 440
    Width = 600
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOk: TButton
      Left = 380
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOkClick
    end
    object btnCancel: TButton
      Left = 488
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object gridMaquinas: TcxGrid
    Left = 0
    Top = 60
    Width = 600
    Height = 380
    Align = alClient
    TabOrder = 2
    object tvMaquinas: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsData.Editing = True
      OptionsSelection.CellSelect = True
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colSel: TcxGridColumn
        Caption = 'Asig.'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 60
      end
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Options.Editing = False
        Width = 140
      end
      object colNombre: TcxGridColumn
        Caption = 'Nombre'
        Options.Editing = False
        Width = 360
      end
    end
    object lvMaquinas: TcxGridLevel
      GridView = tvMaquinas
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 540
    Top = 12
  end
end
