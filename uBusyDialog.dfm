object frmBusyDialog: TfrmBusyDialog
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsNone
  Caption = ' '
  ClientHeight = 168
  ClientWidth = 320
  Color = 3553567
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poOwnerFormCenter
  TextHeight = 17
  object pnlBorder: TPanel
    AlignWithMargins = True
    Left = 2
    Top = 2
    Width = 316
    Height = 164
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object pbSpinner: TPaintBox
      Left = 134
      Top = 26
      Width = 48
      Height = 48
      OnPaint = pbSpinnerPaint
    end
    object lblMessage: TLabel
      Left = 16
      Top = 88
      Width = 288
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = 'Cargando datos...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3553567
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      Layout = tlCenter
      ParentFont = False
    end
    object lblSub: TLabel
      Left = 16
      Top = 114
      Width = 288
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = 'Un momento, por favor'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      Layout = tlCenter
      ParentFont = False
    end
  end
end
