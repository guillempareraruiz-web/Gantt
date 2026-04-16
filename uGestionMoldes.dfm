object frmGestionMoldes: TfrmGestionMoldes
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de Moldes y Utillajes'
  ClientHeight = 520
  ClientWidth = 1100
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
    Width = 1100
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 200
      Height = 25
      Caption = 'Moldes y utillajes'
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
      Width = 500
      Height = 15
      Caption = 'Cat'#225'logo de moldes con centros, art'#237'culos y operaciones compatibles'
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
    Width = 1100
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 992
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
    Width = 1100
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
    object btnCentros: TButton
      Left = 296
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Centros...'
      TabOrder = 3
      OnClick = btnCentrosClick
    end
    object btnArticulos: TButton
      Left = 440
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Art'#237'culos...'
      TabOrder = 4
      OnClick = btnArticulosClick
    end
    object btnOperaciones: TButton
      Left = 584
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Operaciones...'
      TabOrder = 5
      OnClick = btnOperacionesClick
    end
  end
  object gridMoldes: TcxGrid
    Left = 0
    Top = 100
    Width = 1100
    Height = 380
    Align = alClient
    TabOrder = 3
    object tvMoldes: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colId: TcxGridColumn
        Caption = 'ID'
        Width = 50
        Options.Editing = False
      end
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 100
      end
      object colDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 200
      end
      object colCavidades: TcxGridColumn
        Caption = 'Cavidades'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 999.000000000000000000
        Width = 80
      end
      object colTMontaje: TcxGridColumn
        Caption = 'T.Montaje (min)'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 100
      end
      object colTDesmontaje: TcxGridColumn
        Caption = 'T.Desmontaje (min)'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 120
      end
      object colTAjuste: TcxGridColumn
        Caption = 'T.Ajuste (min)'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 100
      end
      object colCiclos: TcxGridColumn
        Caption = 'Ciclos'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 999999999.000000000000000000
        Width = 80
      end
      object colUbicacion: TcxGridColumn
        Caption = 'Ubicaci'#243'n'
        Width = 140
      end
      object colDisponible: TcxGridColumn
        Caption = 'Disponible'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 70
      end
    end
    object lvMoldes: TcxGridLevel
      GridView = tvMoldes
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 1040
    Top = 12
  end
end
