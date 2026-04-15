object frmGestionUsuarios: TfrmGestionUsuarios
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de Usuarios'
  ClientHeight = 560
  ClientWidth = 850
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
    Width = 850
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
      Caption = 'Usuarios'
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
      Width = 300
      Height = 15
      Caption = 'Alta, baja y modificaci'#243'n de usuarios del sistema'
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
    Width = 850
    Height = 2
    Align = alTop
    Pen.Color = 14540253
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 520
    Width = 850
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 742
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
    Top = 62
    Width = 850
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object btnAdd: TButton
      Left = 4
      Top = 4
      Width = 80
      Height = 28
      Caption = 'A'#241'adir'
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnDel: TButton
      Left = 88
      Top = 4
      Width = 80
      Height = 28
      Caption = 'Eliminar'
      TabOrder = 1
      OnClick = btnDelClick
    end
    object btnSave: TButton
      Left = 188
      Top = 4
      Width = 120
      Height = 28
      Caption = 'Guardar cambios'
      TabOrder = 2
      OnClick = btnSaveClick
    end
    object btnResetPwd: TButton
      Left = 328
      Top = 4
      Width = 130
      Height = 28
      Caption = 'Reset Contrase'#241'a'
      TabOrder = 3
      OnClick = btnResetPwdClick
    end
    object btnUnblock: TButton
      Left = 462
      Top = 4
      Width = 100
      Height = 28
      Caption = 'Desbloquear'
      TabOrder = 4
      OnClick = btnUnblockClick
    end
  end
  object gridUsers: TcxGrid
    Left = 0
    Top = 98
    Width = 850
    Height = 422
    Align = alClient
    TabOrder = 3
    object tvUsers: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colUserId: TcxGridColumn
        Caption = 'ID'
        Width = 40
        Options.Editing = False
      end
      object colUserLogin: TcxGridColumn
        Caption = 'Login'
        Width = 120
      end
      object colUserNombre: TcxGridColumn
        Caption = 'Nombre Completo'
        Width = 200
      end
      object colUserEmail: TcxGridColumn
        Caption = 'Email'
        Width = 180
      end
      object colUserRol: TcxGridColumn
        Caption = 'Rol'
        Width = 120
        PropertiesClassName = 'TcxComboBoxProperties'
      end
      object colUserActivo: TcxGridColumn
        Caption = 'Activo'
        Width = 55
        PropertiesClassName = 'TcxCheckBoxProperties'
      end
      object colUserBloqueado: TcxGridColumn
        Caption = 'Bloqueado'
        Width = 70
        PropertiesClassName = 'TcxCheckBoxProperties'
        Options.Editing = False
      end
      object colUserUltimoAcceso: TcxGridColumn
        Caption = #218'ltimo Acceso'
        Width = 140
        Options.Editing = False
      end
    end
    object lvUsers: TcxGridLevel
      GridView = tvUsers
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 790
    Top = 8
  end
end
