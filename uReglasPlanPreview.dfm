object frmReglasPlanPreview: TfrmReglasPlanPreview
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Previsualizaci'#243'n - Planificaci'#243'n por reglas'
  ClientHeight = 680
  ClientWidth = 1120
  Color = clWhite
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
    Width = 1120
    Height = 84
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 12
      Width = 360
      Height = 30
      Caption = 'Orden propuesto (sin aplicar)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 20
      Top = 50
      Width = 400
      Height = 15
      Caption = 'Regla:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object pnlKpiPlan: TPanel
      Left = 420
      Top = 16
      Width = 108
      Height = 52
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 0
      object lblKpiPlanVal: TLabel
        Left = 0
        Top = 6
        Width = 108
        Height = 24
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiPlanCap: TLabel
        Left = 0
        Top = 32
        Width = 108
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Planificadas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiSat: TPanel
      Left = 534
      Top = 16
      Width = 108
      Height = 52
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 1
      object lblKpiSatVal: TLabel
        Left = 0
        Top = 6
        Width = 108
        Height = 24
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiSatCap: TLabel
        Left = 0
        Top = 32
        Width = 108
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Saturadas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiFuera: TPanel
      Left = 648
      Top = 16
      Width = 120
      Height = 52
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 2
      object lblKpiFueraVal: TLabel
        Left = 0
        Top = 6
        Width = 120
        Height = 24
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiFueraCap: TLabel
        Left = 0
        Top = 32
        Width = 120
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Fuera de plazo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiRetr: TPanel
      Left = 774
      Top = 16
      Width = 108
      Height = 52
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 3
      object lblKpiRetrVal: TLabel
        Left = 0
        Top = 6
        Width = 108
        Height = 24
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiRetrCap: TLabel
        Left = 0
        Top = 32
        Width = 108
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Retrasos'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiRetrTot: TPanel
      Left = 888
      Top = 16
      Width = 112
      Height = 52
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 4
      object lblKpiRetrTotVal: TLabel
        Left = 0
        Top = 6
        Width = 112
        Height = 24
        Alignment = taCenter
        AutoSize = False
        Caption = '0,0 h'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiRetrTotCap: TLabel
        Left = 0
        Top = 32
        Width = 112
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Retraso total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiMakespan: TPanel
      Left = 1006
      Top = 16
      Width = 96
      Height = 52
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 5
      object lblKpiMakespanVal: TLabel
        Left = 0
        Top = 6
        Width = 96
        Height = 24
        Alignment = taCenter
        AutoSize = False
        Caption = '0,0 h'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiMakespanCap: TLabel
        Left = 0
        Top = 32
        Width = 96
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Makespan'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
  end
  object grdPreview: TcxGrid
    Left = 0
    Top = 84
    Width = 1120
    Height = 596
    Align = alClient
    TabOrder = 1
    object tvPreview: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      object colOrden: TcxGridColumn
        Caption = '#'
        Width = 50
      end
      object colDoc: TcxGridColumn
        Caption = 'Documento'
        Width = 190
      end
      object colCentro: TcxGridColumn
        Caption = 'Centro'
        Width = 140
      end
      object colIni: TcxGridColumn
        Caption = 'Inicio'
        Width = 140
      end
      object colFin: TcxGridColumn
        Caption = 'Fin'
        Width = 140
      end
      object colDurMin: TcxGridColumn
        Caption = 'Dur. (min)'
        Width = 90
      end
      object colCompromiso: TcxGridColumn
        Caption = 'Compromiso'
        Width = 110
      end
      object colRetraso: TcxGridColumn
        Caption = 'Retraso'
        Width = 90
      end
      object colEstado: TcxGridColumn
        Caption = 'Estado'
        Width = 110
      end
    end
    object lvPreview: TcxGridLevel
      GridView = tvPreview
    end
  end
end
