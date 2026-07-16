object frmGestionUtillajes: TfrmGestionUtillajes
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Gesti'#243'n de Utillajes'
  ClientHeight = 540
  ClientWidth = 1400
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
    Width = 1400
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1400
      70)
    object pbKpis: TPaintBox
      Left = 812
      Top = 8
      Width = 572
      Height = 52
      Anchors = [akTop, akRight]
      OnPaint = pbKpisPaint
    end
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 68
      Height = 25
      Caption = 'Utillajes'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 42
      Width = 107
      Height = 15
      Caption = 'Cat'#225'logo de utillajes'
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
    Top = 70
    Width = 1400
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
  end
  object gridUtil: TcxGrid
    Left = 0
    Top = 110
    Width = 1400
    Height = 430
    Align = alClient
    TabOrder = 2
    object tvUtil: TcxGridTableView
      OnDblClick = tvUtilDblClick
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      Styles.OnGetContentStyle = tvUtilGetContentStyle
      object colId: TcxGridColumn
        Caption = 'ID'
        Options.Editing = False
        Width = 50
      end
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Options.Editing = False
        Width = 120
      end
      object colDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Options.Editing = False
        Width = 160
      end
      object colTipo: TcxGridColumn
        Caption = 'Tipo'
        Options.Editing = False
        Width = 110
      end
      object colUbicacion: TcxGridColumn
        Caption = 'Ubicaci'#243'n'
        Options.Editing = False
        Width = 110
      end
      object colEstado: TcxGridColumn
        Caption = 'Estado'
        Options.Editing = False
        Width = 100
      end
      object colSituacion: TcxGridColumn
        Caption = 'Situaci'#243'n'
        Options.Editing = False
        Width = 100
      end
      object colLibreDesde: TcxGridColumn
        Caption = 'Libre a partir de'
        Options.Editing = False
        Width = 110
      end
      object colOFs: TcxGridColumn
        Caption = 'OFs afectadas'
        Options.Editing = False
        Width = 160
      end
      object colCantidad: TcxGridColumn
        Caption = 'Ejemplares'
        Options.Editing = False
        Width = 70
      end
      object colVida: TcxGridColumn
        Caption = 'Vida '#250'til'
        Options.Editing = False
        Width = 140
      end
      object colDisponible: TcxGridColumn
        Caption = 'Disponible'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Options.Editing = False
        Width = 70
      end
      object colActivo: TcxGridColumn
        Caption = 'Activo'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Options.Editing = False
        Width = 60
      end
    end
    object lvUtil: TcxGridLevel
      GridView = tvUtil
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 1340
    Top = 12
  end
end
