object frmSyncBacklogPreview: TfrmSyncBacklogPreview
  Left = 0
  Top = 0
  Caption = 'Sincronizar Backlog desde ERP'
  ClientHeight = 600
  ClientWidth = 1200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      1200
      60)
    object lblTitulo: TLabel
      Left = 12
      Top = 8
      Width = 329
      Height = 20
      Caption = 'Previsualizaci'#243'n: '#243'rdenes de fabricaci'#243'n del ERP'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblResumen: TLabel
      Left = 12
      Top = 34
      Width = 61
      Height = 15
      Caption = 'Cargando...'
    end
    object btnSelectAll: TcxButton
      Left = 750
      Top = 18
      Width = 130
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Marcar todos'
      TabOrder = 0
      OnClick = btnSelectAllClick
    end
    object btnDeselectAll: TcxButton
      Left = 886
      Top = 18
      Width = 130
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Desmarcar todos'
      TabOrder = 1
      OnClick = btnDeselectAllClick
    end
    object btnAgrupar: TcxButton
      Left = 1022
      Top = 18
      Width = 160
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Agrupar por OF/OT/OP'
      TabOrder = 2
      OnClick = btnAgruparClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 552
    Width = 1200
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      1200
      48)
    object btnAplicar: TcxButton
      Left = 880
      Top = 10
      Width = 200
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Sincronizar seleccionados'
      Default = True
      TabOrder = 0
      OnClick = btnAplicarClick
    end
    object btnCancelar: TcxButton
      Left = 1086
      Top = 10
      Width = 100
      Height = 30
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object Grid: TcxGrid
    Left = 0
    Top = 60
    Width = 1200
    Height = 492
    Align = alClient
    TabOrder = 2
    object GridView: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      OnCustomDrawCell = GridViewCustomDrawCell
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsCustomize.ColumnsQuickCustomization = True
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      object colAplicar: TcxGridColumn
        Caption = 'Aplicar'
        DataBinding.ValueType = 'Boolean'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 55
      end
      object colTipo: TcxGridColumn
        Caption = 'Tipo'
        Width = 50
      end
      object colOF: TcxGridColumn
        Caption = 'OF'
        Width = 90
      end
      object colOT: TcxGridColumn
        Caption = 'OT'
        Width = 70
      end
      object colOP: TcxGridColumn
        Caption = 'OP'
        Width = 60
      end
      object colNivel: TcxGridColumn
        Caption = 'Nivel'
        DataBinding.ValueType = 'Integer'
        Visible = False
        Width = 50
      end
      object colClaveERP: TcxGridColumn
        Caption = 'Clave ERP'
        Width = 160
      end
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'digo'
        Width = 80
      end
      object colDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 260
      end
      object colArticulo: TcxGridColumn
        Caption = 'Art'#237'culo'
        Width = 100
      end
      object colCantidad: TcxGridColumn
        Caption = 'Cantidad'
        DataBinding.ValueType = 'Float'
        Width = 80
      end
      object colCentroPref: TcxGridColumn
        Caption = 'Centro'
        Width = 90
      end
      object colFechaCompromiso: TcxGridColumn
        Caption = 'Fecha entrega'
        DataBinding.ValueType = 'DateTime'
        Width = 110
      end
      object colHorasEst: TcxGridColumn
        Caption = 'Horas'
        DataBinding.ValueType = 'Float'
        Width = 70
      end
      object colEstado: TcxGridColumn
        Caption = 'Estado ERP'
        Width = 80
      end
      object colAccion: TcxGridColumn
        Caption = 'Acci'#243'n'
        Width = 100
      end
    end
    object GridLevel: TcxGridLevel
      GridView = GridView
    end
  end
end
