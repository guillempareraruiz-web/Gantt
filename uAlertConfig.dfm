object frmAlertConfig: TfrmAlertConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Configuraci'#243'n de alertas'
  ClientHeight = 540
  ClientWidth = 720
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 8776698
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      AlignWithMargins = True
      Left = 12
      Top = 0
      Width = 500
      Height = 56
      Margins.Left = 12
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption =
        'Configuraci'#243'n de alertas'#13#10'Active las que quiera vigilar y ajuste' +
        ' su importancia (peso 1-100).'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
  end
  object Grid: TcxGrid
    Left = 0
    Top = 56
    Width = 720
    Height = 425
    Align = alClient
    TabOrder = 1
    object tv: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsBehavior.IncSearch = True
      OptionsCustomize.ColumnFiltering = False
      OptionsCustomize.ColumnGrouping = False
      OptionsData.Deleting = False
      OptionsData.Editing = True
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = True
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colCodigo: TcxGridColumn
        Caption = 'C'#243'd.'
        Options.Editing = False
        Width = 60
      end
      object colAlerta: TcxGridColumn
        Caption = 'Alerta'
        Options.Editing = False
        Width = 360
      end
      object colActiva: TcxGridColumn
        Caption = 'Activa'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Width = 70
      end
      object colPeso: TcxGridColumn
        Caption = 'Peso'
        PropertiesClassName = 'TcxSpinEditProperties'
        Properties.MinValue = 1.000000000000000000
        Properties.MaxValue = 100.000000000000000000
        Width = 80
      end
      object colEstado: TcxGridColumn
        Caption = 'Estado'
        Options.Editing = False
        Width = 110
      end
    end
    object lv: TcxGridLevel
      GridView = tv
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 481
    Width = 720
    Height = 59
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object btnGuardar: TButton
      AlignWithMargins = True
      Left = 487
      Top = 12
      Width = 110
      Height = 35
      Margins.Left = 4
      Margins.Top = 12
      Margins.Right = 4
      Margins.Bottom = 12
      Align = alRight
      Caption = 'Guardar'
      Default = True
      TabOrder = 0
      OnClick = btnGuardarClick
    end
    object btnCancelar: TButton
      AlignWithMargins = True
      Left = 605
      Top = 12
      Width = 103
      Height = 35
      Margins.Left = 4
      Margins.Top = 12
      Margins.Right = 12
      Margins.Bottom = 12
      Align = alRight
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
end
