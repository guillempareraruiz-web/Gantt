object frmLoteViewer: TfrmLoteViewer
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Contenido del lote'
  ClientHeight = 520
  ClientWidth = 780
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Padding.Left = 8
  Padding.Top = 8
  Padding.Right = 8
  Padding.Bottom = 8
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 8
    Top = 8
    Width = 764
    Height = 96
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 4
      Top = 4
      Width = 32
      Height = 19
      Caption = 'Lote'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6052910
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblResumen: TLabel
      Left = 4
      Top = 28
      Width = 50
      Height = 15
      Caption = 'Resumen'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblKpis: TLabel
      Left = 4
      Top = 52
      Width = 756
      Height = 30
      AutoSize = False
      Caption = ' '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3618615
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object pnlConfig: TPanel
    Left = 8
    Top = 104
    Width = 764
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    Color = 15921906
    ParentBackground = False
    TabOrder = 1
    object lblModo: TLabel
      Left = 8
      Top = 16
      Width = 32
      Height = 15
      Caption = 'Modo:'
    end
    object lblSetup: TLabel
      Left = 248
      Top = 16
      Width = 96
      Height = 15
      Caption = 'Setup (min):'
    end
    object cboModo: TComboBox
      Left = 48
      Top = 12
      Width = 184
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      Items.Strings = (
        'Secuencial (suma)'
        'Paralelo (m'#225'ximo)')
    end
    object edSetupMin: TEdit
      Left = 352
      Top = 12
      Width = 80
      Height = 23
      TabOrder = 1
      Text = '0'
    end
    object btnAplicar: TButton
      Left = 448
      Top = 11
      Width = 100
      Height = 25
      Caption = 'Aplicar'
      TabOrder = 2
      OnClick = btnAplicarClick
    end
  end
  object grdOps: TcxGrid
    Left = 8
    Top = 152
    Width = 764
    Height = 312
    Align = alClient
    TabOrder = 2
    object tvOps: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      OnDblClick = tvOpsDblClick
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      object colNodeId: TcxGridColumn
        Caption = 'Nodo'
        Width = 60
      end
      object colDataId: TcxGridColumn
        Caption = 'DataId'
        Visible = False
      end
      object colOperacion: TcxGridColumn
        Caption = 'Operaci'#243'n'
        Width = 120
      end
      object colOF: TcxGridColumn
        Caption = 'OF'
        Width = 90
      end
      object colArticulo: TcxGridColumn
        Caption = 'Art'#237'culo'
        Width = 100
      end
      object colDescripcion: TcxGridColumn
        Caption = 'Descripci'#243'n'
        Width = 200
      end
      object colInicio: TcxGridColumn
        Caption = 'Inicio'
        PropertiesClassName = 'TcxDateEditProperties'
        Properties.Kind = ckDateTime
        Width = 110
      end
      object colFin: TcxGridColumn
        Caption = 'Fin'
        PropertiesClassName = 'TcxDateEditProperties'
        Properties.Kind = ckDateTime
        Width = 110
      end
      object colDuracion: TcxGridColumn
        Caption = 'Dur. (min)'
        Width = 70
      end
      object colDurOrig: TcxGridColumn
        Caption = 'Dur. orig.'
        Width = 70
      end
    end
    object lvOps: TcxGridLevel
      GridView = tvOps
    end
  end
  object pnlBottom: TPanel
    Left = 8
    Top = 464
    Width = 764
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnQuitar: TButton
      Left = 4
      Top = 11
      Width = 160
      Height = 27
      Caption = 'Quitar del lote'
      TabOrder = 0
      OnClick = btnQuitarClick
    end
    object btnDesplanificar: TButton
      Left = 172
      Top = 11
      Width = 160
      Height = 27
      Caption = 'Desplanificar'
      TabOrder = 1
      OnClick = btnDesplanificarClick
    end
    object btnCerrar: TButton
      Left = 660
      Top = 11
      Width = 100
      Height = 27
      Caption = 'Cerrar'
      ModalResult = 2
      TabOrder = 2
    end
  end
end
