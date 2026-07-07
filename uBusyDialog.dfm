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
  PixelsPerInch = 96
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
      Width = 281
      Height = 49
      Alignment = taCenter
      AutoSize = False
      Caption = 'Cargando datos...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3553567
      Font.Height = -15
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lblSub: TLabel
      Left = 9
      Top = 136
      Width = 295
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = 'Un momento, por favor'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
  end
end
