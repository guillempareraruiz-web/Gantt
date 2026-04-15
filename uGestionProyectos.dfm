object frmGestionProyectos: TfrmGestionProyectos
  Left = 0
  Top = 0
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
      Width = 200
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
      Width = 400
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
  object pnlBottom: TPanel
    Left = 0
    Top = 480
    Width = 920
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 812
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Cerrar'
      Cancel = True
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 60
    Width = 920
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
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
    Height = 380
    Align = alClient
    TabOrder = 3
    object tvProyectos: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colProjId: TcxGridColumn
        Caption = 'ID'
        Width = 50
        Options.Editing = False
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
        Width = 100
        Options.Editing = False
      end
      object colProjBasado: TcxGridColumn
        Caption = 'Basado en'
        Width = 150
        Options.Editing = False
      end
      object colProjFecha: TcxGridColumn
        Caption = 'Creado'
        Width = 120
        Options.Editing = False
      end
      object colProjActivo: TcxGridColumn
        Caption = 'Activo'
        Width = 80
        Options.Editing = False
      end
    end
    object lvProyectos: TcxGridLevel
      GridView = tvProyectos
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 860
    Top = 12
  end
end
