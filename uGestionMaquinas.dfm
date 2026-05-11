object frmGestionMaquinas: TfrmGestionMaquinas
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de M'#225'quinas'
  ClientHeight = 520
  ClientWidth = 800
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 78
      Height = 25
      Caption = 'M'#225'quinas'
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
      Width = 260
      Height = 15
      Caption = 'M'#225'quinas asignables a uno o varios centros'
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
    Width = 800
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 692
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 60
    Width = 800
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object btnAdd: TButton
      Left = 4
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Nuevo'
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnDel: TButton
      Left = 88
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Eliminar'
      TabOrder = 1
      OnClick = btnDelClick
    end
    object btnSave: TButton
      Left = 172
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Guardar cambios'
      TabOrder = 2
      OnClick = btnSaveClick
    end
    object btnConfigurarColumnas: TButton
      Left = 296
      Top = 6
      Width = 180
      Height = 28
      Caption = 'Configurar columnas...'
      TabOrder = 3
      Visible = False
      OnClick = btnConfigurarColumnasClick
    end
  end
  object gridMaquinas: TcxGrid
    Left = 0
    Top = 100
    Width = 800
    Height = 380
    Align = alClient
    TabOrder = 3
    object tvMaquinas: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colMaquinaId: TcxGridColumn
        Caption = 'ID'
        Options.Editing = False
        Width = 50
      end
      object colMaquinaCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 140
      end
      object colMaquinaNombre: TcxGridColumn
        Caption = 'Nombre'
        Width = 320
      end
      object colMaquinaOrden: TcxGridColumn
        Caption = 'Orden'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 80
      end
      object colMaquinaActivo: TcxGridColumn
        Caption = 'Activo'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 70
      end
    end
    object lvMaquinas: TcxGridLevel
      GridView = tvMaquinas
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 740
    Top = 12
  end
end
