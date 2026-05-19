object frmExcepcionRecurrente: TfrmExcepcionRecurrente
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Excepci'#243'n recurrente'
  ClientHeight = 540
  ClientWidth = 500
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
    Width = 500
    Height = 250
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblPatron: TLabel
      Left = 16
      Top = 8
      Width = 100
      Height = 17
      Caption = 'Patr'#243'n recurrente'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblOrdinal: TLabel
      Left = 16
      Top = 36
      Width = 38
      Height = 15
      Caption = 'Cada:'
    end
    object lblDia: TLabel
      Left = 200
      Top = 36
      Width = 24
      Height = 15
      Caption = 'd'#237'a:'
    end
    object lblAnio: TLabel
      Left = 380
      Top = 36
      Width = 26
      Height = 15
      Caption = 'A'#241'o:'
    end
    object lblHoraIni: TLabel
      Left = 200
      Top = 108
      Width = 60
      Height = 15
      Caption = 'Hora ini.:'
    end
    object lblHoraFin: TLabel
      Left = 340
      Top = 108
      Width = 60
      Height = 15
      Caption = 'Hora fin.:'
    end
    object lblDescripcion: TLabel
      Left = 16
      Top = 168
      Width = 90
      Height = 15
      Caption = 'Descripci'#243'n:'
    end
    object cbOrdinal: TComboBox
      Left = 16
      Top = 56
      Width = 170
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbOrdinalChange
    end
    object cbDia: TComboBox
      Left = 200
      Top = 56
      Width = 160
      Height = 23
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbDiaChange
    end
    object edAnio: TEdit
      Left = 380
      Top = 56
      Width = 50
      Height = 23
      ReadOnly = True
      TabOrder = 2
      Text = '2026'
    end
    object udAnio: TUpDown
      Left = 430
      Top = 56
      Width = 17
      Height = 23
      Associate = edAnio
      Min = 2024
      Max = 2032
      Position = 2026
      TabOrder = 3
      OnClick = udAnioClick
    end
    object rbFestivo: TRadioButton
      Left = 16
      Top = 92
      Width = 170
      Height = 17
      Caption = 'Festivo (d'#237'a entero)'
      Checked = True
      TabOrder = 4
      TabStop = True
      OnClick = rbFestivoClick
    end
    object rbPausa: TRadioButton
      Left = 16
      Top = 112
      Width = 170
      Height = 17
      Caption = 'Pausa no laborable'
      TabOrder = 5
      OnClick = rbPausaClick
    end
    object dtHoraIni: TDateTimePicker
      Left = 264
      Top = 104
      Width = 70
      Height = 23
      Date = 45810.000000000000000000
      Time = 0.541666666666666700
      Kind = dtkTime
      TabOrder = 6
    end
    object dtHoraFin: TDateTimePicker
      Left = 404
      Top = 104
      Width = 70
      Height = 23
      Date = 45810.000000000000000000
      Time = 0.625000000000000000
      Kind = dtkTime
      TabOrder = 7
    end
    object edDescripcion: TEdit
      Left = 16
      Top = 188
      Width = 460
      Height = 23
      TabOrder = 8
    end
  end
  object lblPreviewTitulo: TLabel
    Left = 16
    Top = 252
    Width = 200
    Height = 17
    Caption = 'Vista previa:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 4474440
    Font.Height = -13
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object lbPreview: TListBox
    Left = 16
    Top = 272
    Width = 460
    Height = 200
    Anchors = [akLeft, akTop, akRight, akBottom]
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
    Top = 488
    Width = 500
    Height = 52
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCrear: TButton
      Left = 300
      Top = 12
      Width = 90
      Height = 28
      Caption = 'Crear'
      Default = True
      TabOrder = 0
      OnClick = btnCrearClick
    end
    object btnCancel: TButton
      Left = 400
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
