object frmGestionMarkers: TfrmGestionMarkers
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Gesti'#243'n de Marcadores'
  ClientHeight = 500
  ClientWidth = 900
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
    Width = 900
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 101
      Height = 25
      Caption = 'Marcadores'
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
      Width = 228
      Height = 15
      Caption = 'Marcadores temporales del proyecto activo'
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
    Width = 900
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
    object btnEdit: TButton
      Left = 88
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Editar'
      TabOrder = 1
      OnClick = btnEditClick
    end
    object btnDel: TButton
      Left = 172
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Eliminar'
      TabOrder = 2
      OnClick = btnDelClick
    end
    object btnSave: TButton
      Left = 258
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Guardar cambios'
      TabOrder = 3
      OnClick = btnSaveClick
    end
  end
  object gridMarkers: TcxGrid
    Left = 0
    Top = 100
    Width = 900
    Height = 400
    Align = alClient
    TabOrder = 2
    ExplicitHeight = 360
    object tvMarkers: TcxGridTableView
      OnDblClick = tvMarkersDblClick
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colId: TcxGridColumn
        Caption = 'ID'
        Options.Editing = False
        Width = 50
      end
      object colCaption: TcxGridColumn
        Caption = 'Texto'
        Width = 300
      end
      object colFechaHora: TcxGridColumn
        Caption = 'Fecha / hora'
        PropertiesClassName = 'TcxDateEditProperties'
        Width = 140
      end
      object colColor: TcxGridColumn
        Caption = 'Color'
        PropertiesClassName = 'TcxButtonEditProperties'
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Properties.ReadOnly = True
        Properties.OnButtonClick = colColorButtonClick
        OnCustomDrawCell = colColorCustomDrawCell
        Width = 110
      end
      object colVisible: TcxGridColumn
        Caption = 'Visible'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 60
      end
      object colMovible: TcxGridColumn
        Caption = 'Movible'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 70
      end
    end
    object lvMarkers: TcxGridLevel
      GridView = tvMarkers
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 840
    Top = 12
  end
  object ColorDialog: TColorDialog
    Left = 840
    Top = 68
  end
end
