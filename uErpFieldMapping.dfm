object frmErpFieldMapping: TfrmErpFieldMapping
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Mapeo de campos ERP'
  ClientHeight = 560
  ClientWidth = 760
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
    Width = 760
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 320
      Height = 25
      AutoSize = False
      Caption = 'Mapeo de campos ERP'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 33
      Width = 540
      Height = 16
      AutoSize = False
      Caption = 'Asocia cada columna del Backlog a una expresi'#243'n SQL de Sage (perfil integrador)'
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
    Top = 520
    Width = 760
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCerrar: TcxButton
      Left = 648
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cerrar'
      Default = True
      ModalResult = 2
      TabOrder = 0
    end
  end
  object grdCols: TcxGrid
    Left = 0
    Top = 56
    Width = 760
    Height = 230
    Align = alTop
    TabOrder = 2
    object tvCols: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      OnFocusedRecordChanged = tvColsFocusedRecordChanged
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      object colCaption: TcxGridColumn
        Caption = 'Columna'
        Options.Editing = False
        Width = 180
      end
      object colFieldKey: TcxGridColumn
        Caption = 'FieldKey'
        Options.Editing = False
        Width = 130
      end
      object colErp: TcxGridColumn
        Caption = 'ERP'
        Options.Editing = False
        Width = 70
      end
      object colExpr: TcxGridColumn
        Caption = 'Expresi'#243'n SQL'
        Options.Editing = False
        Width = 360
      end
    end
    object lvCols: TcxGridLevel
      GridView = tvCols
    end
  end
  object pnlEdit: TPanel
    Left = 0
    Top = 286
    Width = 760
    Height = 234
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object lblColSel: TLabel
      Left = 16
      Top = 12
      Width = 200
      Height = 15
      Caption = '(seleccione una columna)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblExpr: TLabel
      Left = 16
      Top = 44
      Width = 200
      Height = 15
      Caption = 'Expresi'#243'n SQL (campo Sage)'
    end
    object lblJoins: TLabel
      Left = 16
      Top = 96
      Width = 200
      Height = 15
      Caption = 'JOINs adicionales (opcional)'
    end
    object edtExpr: TcxTextEdit
      Left = 16
      Top = 62
      Properties.Nullstring = '(p.ej. [of].CampoLibre1)'
      TabOrder = 0
      Width = 728
    end
    object memJoins: TcxMemo
      Left = 16
      Top = 114
      Properties.ScrollBars = ssVertical
      TabOrder = 1
      Height = 56
      Width = 728
    end
    object chkActivo: TcxCheckBox
      Left = 14
      Top = 178
      Caption = 'Activo (aplicar en sincronizaci'#243'n)'
      State = cbsChecked
      Properties.ValueChecked = True
      TabOrder = 2
      Transparent = True
      Width = 240
    end
    object btnProbar: TcxButton
      Left = 380
      Top = 176
      Width = 110
      Height = 28
      Caption = 'Probar'
      TabOrder = 3
      OnClick = btnProbarClick
    end
    object btnGuardar: TcxButton
      Left = 498
      Top = 176
      Width = 110
      Height = 28
      Caption = 'Guardar'
      TabOrder = 4
      OnClick = btnGuardarClick
    end
    object btnQuitar: TcxButton
      Left = 616
      Top = 176
      Width = 128
      Height = 28
      Caption = 'Quitar mapeo'
      TabOrder = 5
      OnClick = btnQuitarClick
    end
  end
end
