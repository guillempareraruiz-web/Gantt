object frmAsignarCentrosMolde: TfrmAsignarCentrosMolde
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Asignar Centros'
  ClientHeight = 420
  ClientWidth = 400
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 300
      Height = 19
      Caption = 'Centros donde se puede usar este molde'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 28
      Width = 300
      Height = 15
      Caption = '--'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 380
    Width = 400
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 188
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 292
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object clbItems: TCheckListBox
    Left = 0
    Top = 50
    Width = 400
    Height = 330
    Align = alClient
    ItemHeight = 17
    TabOrder = 2
  end
end
