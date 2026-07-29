object frmGestionOperaris: TfrmGestionOperaris
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Gesti'#243'n de Operarios'
  ClientHeight = 480
  ClientWidth = 980
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
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
  object pnlToolbar: TPanel
    Left = 0
    Top = 60
    Width = 980
    Height = 33
    Align = alTop
    BevelOuter = bvNone
    Color = 14869218
    ParentBackground = False
    TabOrder = 1
    object btnAdd: TcxButton
      Left = 6
      Top = 5
      Width = 80
      Height = 23
      Caption = 'Nuevo'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnDel: TcxButton
      Left = 90
      Top = 5
      Width = 80
      Height = 23
      Caption = 'Eliminar'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 1
      OnClick = btnDelClick
    end
    object btnSave: TcxButton
      Left = 174
      Top = 5
      Width = 120
      Height = 23
      Caption = 'Guardar cambios'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 2
      OnClick = btnSaveClick
    end
    object btnDepartamentos: TcxButton
      Left = 298
      Top = 5
      Width = 180
      Height = 23
      Caption = 'Asignar Departamentos...'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 3
      OnClick = btnDepartamentosClick
    end
    object btnPolivalencia: TcxButton
      Left = 482
      Top = 5
      Width = 180
      Height = 23
      Caption = 'Polivalencia y coste...'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 4
      OnClick = btnPolivalenciaClick
    end
    object btnMatriz: TcxButton
      Left = 666
      Top = 5
      Width = 160
      Height = 23
      Caption = 'Matriz polivalencia'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 5
      OnClick = btnMatrizClick
    end
    object btnConfigurarColumnas: TcxButton
      Left = 830
      Top = 5
      Width = 144
      Height = 23
      Caption = 'Configurar columnas...'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 6
      Visible = False
      OnClick = btnConfigurarColumnasClick
    end
  end
  object gridOperaris: TcxGrid
    Left = 0
    Top = 93
    Width = 980
    Height = 387
    Align = alClient
    TabOrder = 2
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
        Caption = 'Habilidades'
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
