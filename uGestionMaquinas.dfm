object frmGestionMaquinas: TfrmGestionMaquinas
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de M'#225'quinas'
  ClientHeight = 560
  ClientWidth = 1180
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
    Width = 1180
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
      Caption = 'Ficha t'#233'cnica, capacidad y estado operativo'
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
    Top = 520
    Width = 1180
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 1072
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
    Width = 1180
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
    Width = 1180
    Height = 420
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
        Width = 110
      end
      object colMaquinaNombre: TcxGridColumn
        Caption = 'Nombre'
        Width = 220
      end
      object colMaquinaTipo: TcxGridColumn
        Caption = 'Tipo'
        Width = 110
      end
      object colMaquinaModelo: TcxGridColumn
        Caption = 'Modelo'
        Width = 130
      end
      object colMaquinaFabricante: TcxGridColumn
        Caption = 'Fabricante'
        Width = 130
      end
      object colMaquinaNumeroSerie: TcxGridColumn
        Caption = 'N'#186' Serie'
        Width = 120
      end
      object colMaquinaDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 200
      end
      object colMaquinaFechaPM: TcxGridColumn
        Caption = 'Puesta marcha'
        PropertiesClassName = 'TcxDateEditProperties'
        Width = 110
      end
      object colMaquinaEfficiency: TcxGridColumn
        Caption = 'Eficiencia'
        PropertiesClassName = 'TcxCalcEditProperties'
        Properties.DisplayFormat = '0.00'
        Width = 80
      end
      object colMaquinaMaxLoad: TcxGridColumn
        Caption = '% Carga m'#225'x'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 100.000000000000000000
        Width = 90
      end
      object colMaquinaCoste: TcxGridColumn
        Caption = 'Coste/h'
        PropertiesClassName = 'TcxCalcEditProperties'
        Properties.DisplayFormat = '0.00'
        Width = 80
      end
      object colMaquinaPlanificable: TcxGridColumn
        Caption = 'Planificable'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 90
      end
      object colMaquinaCuelloBotella: TcxGridColumn
        Caption = 'Cuello botella'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 100
      end
      object colMaquinaPrioridad: TcxGridColumn
        Caption = 'Prioridad asig.'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 110
      end
      object colMaquinaEstado: TcxGridColumn
        Caption = 'Estado'
        PropertiesClassName = 'TcxComboBoxProperties'
        Properties.DropDownListStyle = lsFixedList
        Properties.Items.Strings = (
          'Disponible'
          'Mantenimiento'
          'Averiada'
          'Baja')
        Width = 110
      end
      object colMaquinaHoras: TcxGridColumn
        Caption = 'Horas func.'
        PropertiesClassName = 'TcxCalcEditProperties'
        Properties.DisplayFormat = '0.00'
        Width = 90
      end
      object colMaquinaFechaProxRev: TcxGridColumn
        Caption = 'Pr'#243'x. revisi'#243'n'
        PropertiesClassName = 'TcxDateEditProperties'
        Width = 110
      end
      object colMaquinaOrden: TcxGridColumn
        Caption = 'Orden'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 70
      end
      object colMaquinaActivo: TcxGridColumn
        Caption = 'Activo'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 60
      end
    end
    object lvMaquinas: TcxGridLevel
      GridView = tvMaquinas
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 1120
    Top = 12
  end
end
