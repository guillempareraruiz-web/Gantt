object frmGestionRoles: TfrmGestionRoles
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de Roles y Permisos'
  ClientHeight = 560
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
      Width = 200
      Height = 25
      Caption = 'Roles y Permisos'
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
      Width = 250
      Height = 15
      Caption = 'Configuraci'#243'n de roles y asignaci'#243'n de permisos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object shpHeaderLine: TShape
    Left = 0
    Top = 60
    Width = 800
    Height = 2
    Align = alTop
    Pen.Color = 14540253
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 520
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
      Caption = 'Cerrar'
      Cancel = True
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pc: TcxPageControl
    Left = 0
    Top = 62
    Width = 800
    Height = 458
    Align = alClient
    TabOrder = 2
    Properties.ActivePage = tabRoles
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 454
    ClientRectLeft = 4
    ClientRectRight = 796
    ClientRectTop = 26
    object tabRoles: TcxTabSheet
      Caption = ' Roles '
      object pnlRolesToolbar: TPanel
        Left = 0
        Top = 0
        Width = 792
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnRoleAdd: TButton
          Left = 4
          Top = 4
          Width = 80
          Height = 28
          Caption = 'A'#241'adir'
          TabOrder = 0
          OnClick = btnRoleAddClick
        end
        object btnRoleDel: TButton
          Left = 88
          Top = 4
          Width = 80
          Height = 28
          Caption = 'Eliminar'
          TabOrder = 1
          OnClick = btnRoleDelClick
        end
        object btnRoleSave: TButton
          Left = 188
          Top = 4
          Width = 120
          Height = 28
          Caption = 'Guardar cambios'
          TabOrder = 2
          OnClick = btnRoleSaveClick
        end
      end
      object gridRoles: TcxGrid
        Left = 0
        Top = 36
        Width = 792
        Height = 392
        Align = alClient
        TabOrder = 1
        object tvRoles: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colRoleCodigo: TcxGridColumn
            Caption = 'C'#243'digo'
            Width = 120
          end
          object colRoleNombre: TcxGridColumn
            Caption = 'Nombre'
            Width = 200
          end
          object colRoleDescripcion: TcxGridColumn
            Caption = 'Descripci'#243'n'
            Width = 300
          end
          object colRoleActivo: TcxGridColumn
            Caption = 'Activo'
            Width = 60
            PropertiesClassName = 'TcxCheckBoxProperties'
          end
        end
        object lvRoles: TcxGridLevel
          GridView = tvRoles
        end
      end
    end
    object tabPermisos: TcxTabSheet
      Caption = ' Permisos por Rol '
      object splPermisos: TSplitter
        Left = 250
        Top = 0
        Width = 5
        Height = 428
      end
      object pnlPermRoles: TPanel
        Left = 0
        Top = 0
        Width = 250
        Height = 428
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblPermRol: TLabel
          Left = 8
          Top = 8
          Width = 74
          Height = 15
          Caption = 'Seleccione Rol:'
        end
        object gridPermRoles: TcxGrid
          Left = 0
          Top = 28
          Width = 250
          Height = 400
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvPermRoles: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            OnFocusedRecordChanged = tvPermRolesFocusedRecordChanged
            object colPermRolNombre: TcxGridColumn
              Caption = 'Rol'
              Width = 230
            end
          end
          object lvPermRoles: TcxGridLevel
            GridView = tvPermRoles
          end
        end
      end
      object pnlPermRight: TPanel
        Left = 255
        Top = 0
        Width = 537
        Height = 428
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object pnlPermToolbar: TPanel
          Left = 0
          Top = 0
          Width = 537
          Height = 36
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object btnPermSave: TButton
            Left = 4
            Top = 4
            Width = 120
            Height = 28
            Caption = 'Guardar cambios'
            TabOrder = 0
            OnClick = btnPermSaveClick
          end
        end
        object gridPermisos: TcxGrid
          Left = 0
          Top = 36
          Width = 537
          Height = 392
          Align = alClient
          TabOrder = 1
          object tvPermisos: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colPermModulo: TcxGridColumn
              Caption = 'M'#243'dulo'
              Width = 120
              Options.Editing = False
            end
            object colPermCodigo: TcxGridColumn
              Caption = 'C'#243'digo'
              Width = 130
              Options.Editing = False
            end
            object colPermNombre: TcxGridColumn
              Caption = 'Permiso'
              Width = 180
              Options.Editing = False
            end
            object colPermAsignado: TcxGridColumn
              Caption = 'Asignado'
              Width = 70
              PropertiesClassName = 'TcxCheckBoxProperties'
            end
          end
          object lvPermisos: TcxGridLevel
            GridView = tvPermisos
          end
        end
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 740
    Top = 8
  end
end
