object frmLinkEditor: TfrmLinkEditor
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Editor de Links'
  ClientHeight = 440
  ClientWidth = 750
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = DoKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 750
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 600
      Height = 22
      AutoSize = False
      Caption = 'Editor de Links'
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
      Width = 600
      Height = 18
      AutoSize = False
      Caption = 'Edite el porcentaje de dependencia de cada link'
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
      Width = 750
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 400
    Width = 750
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      750
      40)
    object btnDel: TButton
      Left = 8
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Eliminar link'
      TabOrder = 0
      OnClick = DoDelete
    end
    object btnOK: TButton
      Left = 570
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Aceptar'
      Default = True
      TabOrder = 1
      OnClick = DoOK
    end
    object btnCancel: TButton
      Left = 660
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 2
      OnClick = DoCancel
    end
  end
  object Grid: TcxGrid
    Left = 0
    Top = 60
    Width = 750
    Height = 340
    Align = alClient
    TabOrder = 1
    object View: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colDir: TcxGridColumn
        Caption = 'Tipo'
        Options.Editing = False
        Width = 70
      end
      object colOtherNode: TcxGridColumn
        Caption = 'Nodo relacionado'
        Options.Editing = False
        Width = 200
      end
      object colFromId: TcxGridColumn
        Caption = 'Desde (ID)'
        Options.Editing = False
        Width = 70
      end
      object colToId: TcxGridColumn
        Caption = 'Hacia (ID)'
        Options.Editing = False
        Width = 70
      end
      object colLinkType: TcxGridColumn
        Caption = 'Relaci'#243'n'
        Options.Editing = False
        Width = 100
      end
      object colPct: TcxGridColumn
        Caption = '% Dependencia'
        PropertiesClassName = 'TcxSpinEditProperties'
        Width = 110
      end
    end
    object Level: TcxGridLevel
      GridView = View
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 376
    Top = 224
  end
end
