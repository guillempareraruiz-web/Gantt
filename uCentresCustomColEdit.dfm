object frmCentresCustomColEdit: TfrmCentresCustomColEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Columna personalizada'
  ClientHeight = 320
  ClientWidth = 460
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 15
  object lblColumnKey: TLabel
    Left = 24
    Top = 24
    Width = 100
    Height = 15
    Caption = 'Codigo (ColumnKey)'
  end
  object lblCaption: TLabel
    Left = 24
    Top = 72
    Width = 100
    Height = 15
    Caption = 'Etiqueta'
  end
  object lblDataType: TLabel
    Left = 24
    Top = 120
    Width = 100
    Height = 15
    Caption = 'Tipo de dato'
  end
  object lblOrderDefault: TLabel
    Left = 24
    Top = 168
    Width = 100
    Height = 15
    Caption = 'Orden por defecto'
  end
  object lblWidthDefault: TLabel
    Left = 240
    Top = 168
    Width = 80
    Height = 15
    Caption = 'Ancho (px)'
  end
  object lblHelp: TLabel
    Left = 24
    Top = 216
    Width = 412
    Height = 30
    AutoSize = False
    Caption =
      'ColumnKey solo letras/numeros/guion-bajo. Ejemplo: GPS_LAT, ES_E' +
      'XTERNO. No se puede cambiar despues de crearla.'
    WordWrap = True
  end
  object edtColumnKey: TEdit
    Left = 144
    Top = 21
    Width = 290
    Height = 23
    CharCase = ecUpperCase
    MaxLength = 64
    TabOrder = 0
  end
  object edtCaption: TEdit
    Left = 144
    Top = 69
    Width = 290
    Height = 23
    MaxLength = 200
    TabOrder = 1
  end
  object cmbDataType: TComboBox
    Left = 144
    Top = 117
    Width = 200
    Height = 23
    Style = csDropDownList
    TabOrder = 2
    Items.Strings = (
      'Texto'
      'Numerico'
      'Fecha'
      'Booleano')
  end
  object edtOrderDefault: TSpinEdit
    Left = 144
    Top = 165
    Width = 80
    Height = 24
    MaxValue = 9999
    MinValue = 0
    TabOrder = 3
    Value = 0
  end
  object edtWidthDefault: TSpinEdit
    Left = 326
    Top = 165
    Width = 80
    Height = 24
    MaxValue = 1000
    MinValue = 30
    TabOrder = 4
    Value = 120
  end
  object btnAceptar: TButton
    Left = 240
    Top = 272
    Width = 95
    Height = 30
    Caption = 'Aceptar'
    Default = True
    ModalResult = 1
    TabOrder = 5
    OnClick = btnAceptarClick
  end
  object btnCancelar: TButton
    Left = 341
    Top = 272
    Width = 95
    Height = 30
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 6
  end
end
