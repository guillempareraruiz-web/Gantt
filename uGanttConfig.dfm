object frmGanttConfig: TfrmGanttConfig
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Configuraci'#243'n del Gantt'
  ClientHeight = 480
  ClientWidth = 520
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 520
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 12
      Width = 280
      Height = 25
      Caption = 'Configuraci'#243'n del Gantt'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 440
    Width = 520
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOk: TButton
      Left = 300
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 408
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Cancelar'
      Cancel = True
      ModalResult = 2
      TabOrder = 1
    end
  end
  object vg: TcxVerticalGrid
    Left = 0
    Top = 48
    Width = 520
    Height = 392
    Align = alClient
    OptionsView.RowHeaderWidth = 220
    TabOrder = 2
  end
end
