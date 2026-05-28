object frmGestionProyectos: TfrmGestionProyectos
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Gesti'#243'n de Proyectos'
  ClientHeight = 520
  ClientWidth = 920
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
    Width = 920
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 84
      Height = 25
      Caption = 'Proyectos'
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
      Width = 259
      Height = 15
      Caption = 'Planificaci'#243'n MASTER y escenarios de simulaci'#243'n'
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
    Width = 920
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object btnNuevoEscenario: TButton
      Left = 4
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Nuevo Escenario'
      TabOrder = 0
      OnClick = btnNuevoEscenarioClick
    end
    object btnActivar: TButton
      Left = 148
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Activar Proyecto'
      TabOrder = 1
      OnClick = btnActivarClick
    end
    object btnPromover: TButton
      Left = 272
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Promover a MASTER'
      TabOrder = 2
      OnClick = btnPromoverClick
    end
    object btnEliminar: TButton
      Left = 416
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Eliminar'
      TabOrder = 3
      OnClick = btnEliminarClick
    end
    object btnGuardar: TButton
      Left = 520
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Guardar cambios'
      TabOrder = 4
      OnClick = btnGuardarClick
    end
    object btnAsignarUsuarios: TButton
      Left = 644
      Top = 6
      Width = 150
      Height = 28
      Caption = 'Asignar Usuarios'
      TabOrder = 5
      OnClick = btnAsignarUsuariosClick
    end
  end
  object gridProyectos: TcxGrid
    Left = 0
    Top = 100
    Width = 920
    Height = 420
    Align = alClient
    TabOrder = 2
    ExplicitHeight = 380
    object tvProyectos: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colProjId: TcxGridColumn
        Caption = 'ID'
        Options.Editing = False
        Width = 50
      end
      object colProjCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 120
      end
      object colProjNombre: TcxGridColumn
        Caption = 'Nombre'
        Width = 250
      end
      object colProjDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 200
      end
      object colProjTipo: TcxGridColumn
        Caption = 'Tipo'
        Options.Editing = False
        Width = 100
      end
      object colProjBasado: TcxGridColumn
        Caption = 'Basado en'
        Options.Editing = False
        Width = 150
      end
      object colProjFecha: TcxGridColumn
        Caption = 'Creado'
        Options.Editing = False
        Width = 120
      end
      object colProjActivo: TcxGridColumn
        Caption = 'Activo'
        Options.Editing = False
        Width = 80
      end
      object colProjFechaBloqueo: TcxGridColumn
        Caption = 'Fecha bloqueo'
        PropertiesClassName = 'TcxDateEditProperties'
        Width = 120
      end
      object colProjRowMode: TcxGridColumn
        Caption = 'Modo vista'
        PropertiesClassName = 'TcxComboBoxProperties'
        Properties.DropDownListStyle = lsFixedList
        Properties.Items.Strings = (
          'CENTROS'
          'GRUPO'
          'TREE')
        Width = 95
      end
      object colProjNivelAgrupacion: TcxGridColumn
        Caption = 'Nivel agrup.'
        PropertiesClassName = 'TcxComboBoxProperties'
        Properties.DropDownListStyle = lsFixedList
        Properties.Items.Strings = (
          '1'
          '2')
        Width = 80
      end
    end
    object lvProyectos: TcxGridLevel
      GridView = tvProyectos
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 860
    Top = 12
  end
end
