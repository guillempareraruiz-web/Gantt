object frmCalendarExceptionEditDialog: TfrmCalendarExceptionEditDialog
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Excepci'#243'n del calendario'
  ClientHeight = 280
  ClientWidth = 520
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
    Width = 520
    Height = 232
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 12
      Width = 320
      Height = 18
      Caption = 'Festivo, puente o d'#237'a especial'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -14
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblFecha: TLabel
      Left = 16
      Top = 50
      Width = 39
      Height = 15
      Caption = 'Fecha:'
    end
    object lblHoraIni: TLabel
      Left = 16
      Top = 132
      Width = 56
      Height = 15
      Caption = 'Hora ini.:'
    end
    object lblHoraFin: TLabel
      Left = 16
      Top = 162
      Width = 58
      Height = 15
      Caption = 'Hora fin.:'
    end
    object lblDescripcion: TLabel
      Left = 16
      Top = 196
      Width = 74
      Height = 15
      Caption = 'Descripci'#243'n:'
    end
    object dtFecha: TDateTimePicker
      Left = 100
      Top = 46
      Width = 200
      Height = 23
      Date = 45810.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 0
    end
    object rbFestivo: TRadioButton
      Left = 16
      Top = 80
      Width = 200
      Height = 17
      Caption = 'Festivo / d'#237'a cerrado'
      Checked = True
      TabOrder = 1
      TabStop = True
      OnClick = rbFestivoClick
    end
    object rbLaborable: TRadioButton
      Left = 16
      Top = 104
      Width = 200
      Height = 17
      Caption = 'Laborable parcial (horas custom)'
      TabOrder = 2
      OnClick = rbLaborableClick
    end
    object dtHoraIni: TDateTimePicker
      Left = 100
      Top = 128
      Width = 100
      Height = 23
      Date = 45810.000000000000000000
      Time = 0.333333333333333300
      Kind = dtkTime
      TabOrder = 3
    end
    object dtHoraFin: TDateTimePicker
      Left = 100
      Top = 158
      Width = 100
      Height = 23
      Date = 45810.000000000000000000
      Time = 0.541666666666666700
      Kind = dtkTime
      TabOrder = 4
    end
    object edDescripcion: TEdit
      Left = 100
      Top = 192
      Width = 400
      Height = 23
      TabOrder = 5
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 232
    Width = 520
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 320
      Top = 12
      Width = 90
      Height = 26
      Caption = 'Guardar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 420
      Top = 12
      Width = 90
      Height = 26
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end
