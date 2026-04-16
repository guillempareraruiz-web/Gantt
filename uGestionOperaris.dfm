object frmGestionOperaris: TfrmGestionOperaris
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de Operarios'
  ClientHeight = 520
  ClientWidth = 980
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
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 83
      Height = 25
      Caption = 'Operarios'
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
      Width = 308
      Height = 15
      Caption = 'Operarios con calendario, departamentos y capacitaciones'
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
    Width = 980
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 872
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
    Width = 980
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
    object btnDepartamentos: TButton
      Left = 296
      Top = 6
      Width = 180
      Height = 28
      Caption = 'Asignar Departamentos...'
      TabOrder = 3
      OnClick = btnDepartamentosClick
    end
    object btnCapacitaciones: TButton
      Left = 480
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Capacitaciones...'
      TabOrder = 4
      OnClick = btnCapacitacionesClick
    end
  end
  object gridOperaris: TcxGrid
    Left = 0
    Top = 100
    Width = 980
    Height = 380
    Align = alClient
    TabOrder = 3
    object tvOperaris: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colOpId: TcxGridColumn
        Caption = 'ID'
        Options.Editing = False
        Width = 50
      end
      object colOpNombre: TcxGridColumn
        Caption = 'Nombre'
        Width = 220
      end
      object colOpCalendario: TcxGridColumn
        Caption = 'Calendario'
        PropertiesClassName = 'TcxComboBoxProperties'
        Width = 160
      end
      object colOpActivo: TcxGridColumn
        Caption = 'Activo'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 60
      end
      object colOpDepartamentos: TcxGridColumn
        Caption = 'Departamentos'
        Options.Editing = False
        Width = 240
      end
      object colOpCapacitaciones: TcxGridColumn
        Caption = 'Capacitaciones'
        Options.Editing = False
        Width = 90
      end
    end
    object lvOperaris: TcxGridLevel
      GridView = tvOperaris
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 920
    Top = 12
  end
end
