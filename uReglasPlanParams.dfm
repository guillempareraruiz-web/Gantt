object frmReglasPlanParams: TfrmReglasPlanParams
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Planificaci'#243'n por reglas de prioridad'
  ClientHeight = 620
  ClientWidth = 620
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
    Width = 620
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 10
      Width = 360
      Height = 25
      Caption = 'Planificaci'#243'n por reglas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 20
      Top = 36
      Width = 480
      Height = 15
      Caption = 'Elige c'#243'mo priorizar el trabajo y previsualiza c'#243'mo quedar'#237'a'
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
    Top = 580
    Width = 620
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnComparar: TButton
      Left = 16
      Top = 6
      Width = 150
      Height = 28
      Caption = 'Comparar reglas...'
      ModalResult = 11
      TabOrder = 0
    end
    object btnPrevisualizar: TButton
      Left = 388
      Top = 6
      Width = 110
      Height = 28
      Caption = 'Previsualizar'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
    object btnCancel: TButton
      Left = 506
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Cancelar'
      Cancel = True
      ModalResult = 2
      TabOrder = 2
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 60
    Width = 620
    Height = 520
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblModo: TLabel
      Left = 24
      Top = 16
      Width = 31
      Height = 15
      Caption = 'Modo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblFechaBase: TLabel
      Left = 360
      Top = 16
      Width = 60
      Height = 15
      Caption = 'Fecha base'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblTipo: TLabel
      Left = 24
      Top = 96
      Width = 90
      Height = 15
      Caption = 'Tipo de regla'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblRegla: TLabel
      Left = 24
      Top = 152
      Width = 90
      Height = 15
      Caption = 'Regla'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblDesempate1: TLabel
      Left = 24
      Top = 208
      Width = 110
      Height = 15
      Caption = 'Desempate 1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblDesempate2: TLabel
      Left = 320
      Top = 208
      Width = 110
      Height = 15
      Caption = 'Desempate 2'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblOverrides: TLabel
      Left = 24
      Top = 296
      Width = 480
      Height = 15
      Caption = 'Regla can'#243'nica por centro (vac'#237'o = usa la regla de arriba)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object rbForward: TRadioButton
      Left = 24
      Top = 38
      Width = 300
      Height = 19
      Caption = 'Forward (desde la fecha base hacia delante)'
      TabOrder = 0
    end
    object rbBackward: TRadioButton
      Left = 24
      Top = 60
      Width = 320
      Height = 19
      Caption = 'Backward (desde la fecha de entrega hacia atr'#225's)'
      TabOrder = 1
    end
    object dtFechaBase: TDateTimePicker
      Left = 360
      Top = 36
      Width = 180
      Height = 23
      TabOrder = 2
    end
    object cmbTipo: TComboBox
      Left = 24
      Top = 116
      Width = 516
      Height = 23
      Style = csDropDownList
      TabOrder = 3
      OnChange = cmbTipoChange
    end
    object cmbRegla: TComboBox
      Left = 24
      Top = 172
      Width = 516
      Height = 23
      Style = csDropDownList
      TabOrder = 4
    end
    object cmbDesempate1: TComboBox
      Left = 24
      Top = 228
      Width = 270
      Height = 23
      Style = csDropDownList
      TabOrder = 5
    end
    object cmbDesempate2: TComboBox
      Left = 320
      Top = 228
      Width = 220
      Height = 23
      Style = csDropDownList
      TabOrder = 6
    end
    object chkOverrides: TCheckBox
      Left = 24
      Top = 270
      Width = 400
      Height = 19
      Caption = 'Usar reglas distintas por centro (overrides)'
      TabOrder = 7
      OnClick = chkOverridesClick
    end
    object grdOverrides: TcxGrid
      Left = 24
      Top = 316
      Width = 570
      Height = 192
      TabOrder = 8
      object tvOverrides: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = True
        OptionsView.GroupByBox = False
        object colCentro: TcxGridColumn
          Caption = 'Centro'
          Options.Editing = False
          Width = 280
        end
        object colRegla: TcxGridColumn
          Caption = 'Regla'
          Width = 270
        end
      end
      object lvOverrides: TcxGridLevel
        GridView = tvOverrides
      end
    end
  end
end
