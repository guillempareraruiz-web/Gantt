object frmBusyDialog: TfrmBusyDialog
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = ' '
  ClientHeight = 90
  ClientWidth = 360
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poOwnerFormCenter
  TextHeight = 17
  object pnlBorder: TPanel
    Left = 0
    Top = 0
    Width = 360
    Height = 90
    Align = alClient
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblMessage: TLabel
      AlignWithMargins = True
      Left = 24
      Top = 24
      Width = 308
      Height = 38
      Margins.Left = 24
      Margins.Top = 24
      Margins.Right = 24
      Margins.Bottom = 24
      Align = alClient
      Alignment = taCenter
      Caption = 'Cargando datos...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      Layout = tlCenter
      ParentFont = False
      ExplicitWidth = 122
      ExplicitHeight = 21
    end
  end
end
