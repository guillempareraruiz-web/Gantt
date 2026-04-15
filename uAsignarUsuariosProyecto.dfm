object frmAsignarUsuariosProyecto: TfrmAsignarUsuariosProyecto
  Left = 0
  Top = 0
  Caption = 'Asignar Usuarios al Proyecto'
  ClientHeight = 480
  ClientWidth = 560
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
    Width = 560
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 300
      Height = 25
      Caption = 'Asignar Usuarios'
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
      Caption = 'Seleccione los usuarios con acceso a este proyecto'
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
    Width = 560
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnAceptar: TButton
      Left = 348
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Guardar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TButton
      Left = 452
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Cancelar'
      Cancel = True
      ModalResult = 2
      TabOrder = 1
    end
  end
  object gridUsers: TcxGrid
    Left = 0
    Top = 60
    Width = 560
    Height = 380
    Align = alClient
    TabOrder = 2
    object tvUsers: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colAsignado: TcxGridColumn
        Caption = 'Asignado'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 80
      end
      object colUserLogin: TcxGridColumn
        Caption = 'Login'
        Width = 140
        Options.Editing = False
      end
      object colUserNombre: TcxGridColumn
        Caption = 'Nombre'
        Width = 200
        Options.Editing = False
      end
      object colUserRol: TcxGridColumn
        Caption = 'Rol'
        Width = 120
        Options.Editing = False
      end
    end
    object lvUsers: TcxGridLevel
      GridView = tvUsers
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 500
    Top = 12
  end
end
