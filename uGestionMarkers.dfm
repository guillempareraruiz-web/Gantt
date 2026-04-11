object frmGestionMarkers: TfrmGestionMarkers
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Gesti'#243'n de Marcadores'
  ClientHeight = 520
  ClientWidth = 780
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 780
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 700
      Height = 22
      AutoSize = False
      Caption = 'Gesti'#243'n de Marcadores'
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 33
      Width = 700
      Height = 18
      AutoSize = False
      Caption = 'Visualizar, editar y eliminar marcadores del Gantt'
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object shpHeaderLine: TShape
      Left = 0
      Top = 58
      Width = 780
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 480
    Width = 780
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      780
      40)
    object lblCount: TLabel
      Left = 16
      Top = 12
      Width = 200
      Height = 15
      Caption = '0 marcadores'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnClose: TButton
      Left = 690
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 60
    Width = 780
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object btnEdit: TButton
      Left = 4
      Top = 2
      Width = 80
      Height = 26
      Caption = 'Editar'
      TabOrder = 0
      OnClick = btnEditClick
    end
    object btnDelete: TButton
      Left = 90
      Top = 2
      Width = 100
      Height = 26
      Caption = 'Eliminar sel.'
      TabOrder = 1
      OnClick = btnDeleteClick
    end
    object btnGoTo: TButton
      Left = 196
      Top = 2
      Width = 80
      Height = 26
      Caption = 'Ir a...'
      TabOrder = 2
      OnClick = btnGoToClick
    end
  end
  object grid: TcxGrid
    Left = 0
    Top = 92
    Width = 780
    Height = 388
    Align = alClient
    TabOrder = 1
    object tv: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.MultiSelect = True
      OptionsSelection.CheckBoxVisibility = [cbvDataRow]
      OptionsView.ColumnAutoWidth = True
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colId: TcxGridColumn
        Caption = 'ID'
        MinWidth = 40
        Options.Editing = False
        Options.HorzSizing = False
        Width = 40
      end
      object colCaption: TcxGridColumn
        Caption = 'Nombre'
        MinWidth = 140
        Options.Editing = False
        Width = 180
      end
      object colDateTime: TcxGridColumn
        Caption = 'Fecha / Hora'
        MinWidth = 130
        Options.Editing = False
        Options.HorzSizing = False
        Width = 130
      end
      object colStyle: TcxGridColumn
        Caption = 'Estilo'
        MinWidth = 80
        Options.Editing = False
        Options.HorzSizing = False
        Width = 80
      end
      object colColor: TcxGridColumn
        Caption = 'Color'
        MinWidth = 60
        Options.Editing = False
        Options.HorzSizing = False
        Width = 60
      end
      object colMoveable: TcxGridColumn
        Caption = 'Movible'
        PropertiesClassName = 'TcxCheckBoxProperties'
        MinWidth = 60
        Options.Editing = False
        Options.HorzSizing = False
        Width = 60
      end
      object colVisible: TcxGridColumn
        Caption = 'Visible'
        PropertiesClassName = 'TcxCheckBoxProperties'
        MinWidth = 60
        Options.Editing = False
        Options.HorzSizing = False
        Width = 60
      end
    end
    object lv: TcxGridLevel
      GridView = tv
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 392
    Top = 256
  end
end
