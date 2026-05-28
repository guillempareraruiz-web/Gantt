object frmGestionCentres: TfrmGestionCentres
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Gesti'#243'n de Centros'
  ClientHeight = 540
  ClientWidth = 1320
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
    Width = 1320
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 66
      Height = 25
      Caption = 'Centros'
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
      Width = 268
      Height = 15
      Caption = 'Centros de trabajo con '#225'rea y calendario asignados'
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
    Width = 1320
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
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
    object btnAsignarMaquinas: TButton
      Left = 484
      Top = 6
      Width = 180
      Height = 28
      Caption = 'Asignar m'#225'quinas...'
      TabOrder = 4
      OnClick = btnAsignarMaquinasClick
    end
  end
  object gridCentros: TcxGrid
    Left = 0
    Top = 100
    Width = 1320
    Height = 440
    Align = alClient
    TabOrder = 2
    ExplicitHeight = 400
    object tvCentros: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colCentroId: TcxGridColumn
        Caption = 'ID'
        Options.Editing = False
        Width = 50
      end
      object colCentroCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 100
      end
      object colCentroTitulo: TcxGridColumn
        Caption = 'T'#237'tulo'
        Width = 180
      end
      object colCentroSubtitulo: TcxGridColumn
        Caption = 'Subt'#237'tulo'
        Width = 130
      end
      object colCentroTipo: TcxGridColumn
        Caption = 'Tipo'
        Width = 100
      end
      object colCentroUbicacion: TcxGridColumn
        Caption = 'Ubicaci'#243'n'
        Width = 120
      end
      object colCentroArea: TcxGridColumn
        Caption = #193'rea'
        PropertiesClassName = 'TcxComboBoxProperties'
        Width = 140
      end
      object colCentroCalendario: TcxGridColumn
        Caption = 'Calendario'
        PropertiesClassName = 'TcxComboBoxProperties'
        Width = 140
      end
      object colCentroSecuencial: TcxGridColumn
        Caption = 'Secuencial'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 80
      end
      object colCentroMaxLanes: TcxGridColumn
        Caption = 'MaxLanes'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 999.000000000000000000
        Width = 80
      end
      object colCentroEfficiency: TcxGridColumn
        Caption = 'Eficiencia'
        PropertiesClassName = 'TcxCalcEditProperties'
        Properties.DisplayFormat = '0.00'
        Width = 80
      end
      object colCentroCoste: TcxGridColumn
        Caption = 'Coste/h'
        PropertiesClassName = 'TcxCalcEditProperties'
        Properties.DisplayFormat = '0.00'
        Width = 80
      end
      object colCentroSetup: TcxGridColumn
        Caption = 'Setup def. (min)'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 99999.000000000000000000
        Width = 110
      end
      object colCentroHorizon: TcxGridColumn
        Caption = 'Horiz. plan. (d)'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 100
      end
      object colCentroOrden: TcxGridColumn
        Caption = 'Orden'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        Width = 70
      end
      object colCentroVisible: TcxGridColumn
        Caption = 'Visible'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 60
      end
      object colCentroHabilitado: TcxGridColumn
        Caption = 'Habilitado'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 70
      end
      object colCentroColor: TcxGridColumn
        Caption = 'Color'
        PropertiesClassName = 'TcxButtonEditProperties'
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Properties.ReadOnly = True
        Properties.OnButtonClick = colCentroColorButtonClick
        OnCustomDrawCell = colCentroColorCustomDrawCell
        Width = 110
      end
    end
    object lvCentros: TcxGridLevel
      GridView = tvCentros
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 940
    Top = 12
  end
  object ColorDialog: TColorDialog
    Left = 940
    Top = 68
  end
end
