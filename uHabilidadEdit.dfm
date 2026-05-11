object frmHabilidadEdit: TfrmHabilidadEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Habilidad'
  ClientHeight = 200
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 17
  object pnlBody: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 144
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblCodigo: TLabel
      Left = 16
      Top = 20
      Width = 47
      Height = 17
      Caption = 'C'#243'digo'
    end
    object lblDescripcion: TLabel
      Left = 16
      Top = 72
      Width = 73
      Height = 17
      Caption = 'Descripci'#243'n'
    end
    object edCodigo: TEdit
      Left = 16
      Top = 40
      Width = 200
      Height = 25
      CharCase = ecUpperCase
      TabOrder = 0
    end
    object edDescripcion: TEdit
      Left = 16
      Top = 92
      Width = 388
      Height = 25
      TabOrder = 1
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 144
    Width = 420
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 232
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
      Left = 320
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
