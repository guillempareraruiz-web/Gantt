object frmHabilidadPicker: TfrmHabilidadPicker
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Seleccionar habilidad'
  ClientHeight = 200
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
  object pnlBody: TPanel
    Left = 0
    Top = 0
    Width = 460
    Height = 144
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblHab: TLabel
      Left = 16
      Top = 20
      Width = 56
      Height = 17
      Caption = 'Habilidad'
    end
    object lblNivel: TLabel
      Left = 16
      Top = 76
      Width = 75
      Height = 17
      Caption = 'Nivel m'#237'nimo'
    end
    object cbHabilidad: TComboBox
      Left = 16
      Top = 40
      Width = 428
      Height = 25
      Style = csDropDownList
      TabOrder = 0
    end
    object cbNivel: TComboBox
      Left = 16
      Top = 96
      Width = 200
      Height = 25
      Style = csDropDownList
      TabOrder = 1
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 144
    Width = 460
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 268
      Top = 14
      Width = 80
      Height = 28
      Caption = 'Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 0
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
