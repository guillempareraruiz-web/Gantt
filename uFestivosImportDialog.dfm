object frmFestivosImport: TfrmFestivosImport
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Importar festivos'
  ClientHeight = 460
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 100
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblPlantilla: TLabel
      Left = 16
      Top = 12
      Width = 51
      Height = 15
      Caption = 'Plantilla:'
    end
    object lblAnio: TLabel
      Left = 16
      Top = 44
      Width = 26
      Height = 15
      Caption = 'A'#241'o:'
    end
    object lblInfo: TLabel
      Left = 16
      Top = 76
      Width = 450
      Height = 15
      AutoSize = False
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object cbPlantilla: TComboBox
      Left = 100
      Top = 8
      Width = 365
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbPlantillaChange
    end
    object edAnio: TEdit
      Left = 100
      Top = 40
      Width = 60
      Height = 23
      ReadOnly = True
      TabOrder = 1
      Text = '2026'
    end
    object udAnio: TUpDown
      Left = 160
      Top = 40
      Width = 17
      Height = 23
      Associate = edAnio
      Min = 2024
      Max = 2032
      Position = 2026
      TabOrder = 2
      OnClick = udAnioClick
    end
  end
  object lbPreview: TListBox
    Left = 0
    Top = 100
    Width = 480
    Height = 308
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ItemHeight = 15
    ParentFont = False
    TabOrder = 1
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 408
    Width = 480
    Height = 52
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnImportar: TButton
      Left = 280
      Top = 12
      Width = 90
      Height = 28
      Caption = 'Importar'
      Default = True
      TabOrder = 0
      OnClick = btnImportarClick
    end
    object btnCancel: TButton
      Left = 380
      Top = 12
      Width = 90
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end
