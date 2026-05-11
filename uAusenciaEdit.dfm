object frmAusenciaEdit: TfrmAusenciaEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Ausencia'
  ClientHeight = 420
  ClientWidth = 460
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 460
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 14
      Width = 90
      Height = 21
      Caption = 'Nueva ausencia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 48
    Width = 460
    Height = 316
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblTipo: TLabel
      Left = 16
      Top = 16
      Width = 28
      Height = 17
      Caption = 'Tipo'
    end
    object lblFechaInicio: TLabel
      Left = 16
      Top = 124
      Width = 87
      Height = 17
      Caption = 'Fecha de inicio'
    end
    object lblFechaFin: TLabel
      Left = 232
      Top = 124
      Width = 71
      Height = 17
      Caption = 'Fecha de fin'
    end
    object lblFechaUnica: TLabel
      Left = 16
      Top = 124
      Width = 27
      Height = 17
      Caption = 'D'#237'a'
      Visible = False
    end
    object lblHoraInicio: TLabel
      Left = 16
      Top = 176
      Width = 67
      Height = 17
      Caption = 'Hora inicio'
      Visible = False
    end
    object lblHoraFin: TLabel
      Left = 232
      Top = 176
      Width = 51
      Height = 17
      Caption = 'Hora fin'
      Visible = False
    end
    object lblDescripcion: TLabel
      Left = 16
      Top = 232
      Width = 73
      Height = 17
      Caption = 'Descripci'#243'n'
    end
    object shpTipoColor: TShape
      Left = 232
      Top = 36
      Width = 18
      Height = 18
      Brush.Color = 14598664
      Pen.Color = clGray
    end
    object lblModo: TLabel
      Left = 16
      Top = 76
      Width = 30
      Height = 17
      Caption = 'Modo'
    end
    object cbTipo: TComboBox
      Left = 16
      Top = 36
      Width = 200
      Height = 25
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbTipoChange
    end
    object rbDia: TRadioButton
      Left = 56
      Top = 76
      Width = 130
      Height = 19
      Caption = 'D'#237'a(s) completo(s)'
      Checked = True
      TabOrder = 1
      OnClick = rbModoClick
    end
    object rbHoras: TRadioButton
      Left = 200
      Top = 76
      Width = 100
      Height = 19
      Caption = 'Tramo horario'
      TabOrder = 2
      OnClick = rbModoClick
    end
    object dtpFechaInicio: TDateTimePicker
      Left = 16
      Top = 144
      Width = 200
      Height = 25
      Date = 45000.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 3
      OnChange = dtpFechaInicioChange
    end
    object dtpFechaFin: TDateTimePicker
      Left = 232
      Top = 144
      Width = 200
      Height = 25
      Date = 45001.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 4
    end
    object dtpFechaUnica: TDateTimePicker
      Left = 16
      Top = 144
      Width = 200
      Height = 25
      Date = 45000.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 5
      Visible = False
    end
    object dtpHoraInicio: TDateTimePicker
      Left = 16
      Top = 196
      Width = 100
      Height = 25
      Date = 45000.000000000000000000
      Time = 0.333333333333333000
      Kind = dtkTime
      TabOrder = 6
      Visible = False
      OnChange = dtpHoraInicioChange
    end
    object dtpHoraFin: TDateTimePicker
      Left = 232
      Top = 196
      Width = 100
      Height = 25
      Date = 45000.000000000000000000
      Time = 0.500000000000000000
      Kind = dtkTime
      TabOrder = 7
      Visible = False
    end
    object mmDescripcion: TMemo
      Left = 16
      Top = 252
      Width = 416
      Height = 56
      ScrollBars = ssVertical
      TabOrder = 8
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 364
    Width = 460
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnOK: TButton
      Left = 268
      Top = 14
      Width = 80
      Height = 28
      Caption = 'Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 360
      Top = 14
      Width = 80
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
