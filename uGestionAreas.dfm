object frmGestionAreas: TfrmGestionAreas
  Left = 0
  Top = 0
  Caption = 'Gesti'#243'n de '#193'reas'
  ClientHeight = 480
  ClientWidth = 700
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
    Width = 700
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
      Caption = #193'reas'
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
      Caption = 'Clasificaci'#243'n de centros por '#225'rea'
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
    Width = 700
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 592
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
    Width = 700
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object btnAdd: TButton
      Left = 4
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Nueva'
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
  end
  object gridAreas: TcxGrid
    Left = 0
    Top = 100
    Width = 700
    Height = 340
    Align = alClient
    TabOrder = 3
    object tvAreas: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colAreaId: TcxGridColumn
        Caption = 'ID'
        Width = 50
        Options.Editing = False
      end
      object colAreaCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 120
      end
      object colAreaNombre: TcxGridColumn
        Caption = 'Nombre'
        Width = 300
      end
      object colAreaOrden: TcxGridColumn
        Caption = 'Orden'
        Width = 70
      end
      object colAreaActivo: TcxGridColumn
        Caption = 'Activo'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 70
      end
    end
    object lvAreas: TcxGridLevel
      GridView = tvAreas
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 640
    Top = 12
  end
end
