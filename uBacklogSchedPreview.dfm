object frmBacklogSchedPreview: TfrmBacklogSchedPreview
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Preview de auto-planificaci'#243'n'
  ClientHeight = 580
  ClientWidth = 1220
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 96
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 207
      Height = 25
      Caption = 'Preview de planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object pbKpis: TPaintBox
      Left = 16
      Top = 42
      Width = 1188
      Height = 46
      OnPaint = pbKpisPaint
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 520
    Width = 1000
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnConfirmar: TButton
      Left = 660
      Top = 6
      Width = 160
      Height = 28
      Caption = 'Confirmar y crear nodos'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnVolver: TButton
      Left = 828
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Volver'
      TabOrder = 1
      OnClick = btnVolverClick
    end
    object btnCancel: TButton
      Left = 916
      Top = 6
      Width = 76
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 2
    end
  end
  object grdPreview: TcxGrid
    Left = 0
    Top = 96
    Width = 1000
    Height = 424
    Align = alClient
    TabOrder = 2
    object tvPreview: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsCustomize.ColumnsQuickCustomization = True
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = True
      OptionsView.Indicator = True
      OnCustomDrawCell = tvPreviewCustomDrawCell
      object colOF: TcxGridColumn
        Caption = 'OF'
        Width = 90
      end
      object colOT: TcxGridColumn
        Caption = 'OT'
        Width = 80
      end
      object colDoc: TcxGridColumn
        Caption = 'Documento'
        Width = 140
      end
      object colOrigen: TcxGridColumn
        Caption = 'Origen'
        Width = 70
      end
      object colCentro: TcxGridColumn
        Caption = 'Centro'
        Width = 110
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
        Caption = 'Dur. min'
        Width = 80
      end
      object colCompromiso: TcxGridColumn
        Caption = 'F. Compromiso'
        Width = 120
      end
      object colEstado: TcxGridColumn
        Caption = 'Estado'
        Width = 130
      end
      object colObs: TcxGridColumn
        Caption = 'Observaciones'
        Width = 250
      end
      object colStatusVal: TcxGridColumn
        Caption = 'St'
        Visible = False
        Options.Grouping = False
      end
    end
    object lvPreview: TcxGridLevel
      GridView = tvPreview
    end
  end
end
