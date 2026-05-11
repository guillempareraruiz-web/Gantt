object frmScoreBreakdown: TfrmScoreBreakdown
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Justificaci'#243'n del scoring'
  ClientHeight = 460
  ClientWidth = 660
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
    Width = 660
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 12
      Width = 100
      Height = 21
      Caption = 'Justificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 38
      Width = 80
      Height = 17
      Caption = 'Subtitulo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6316128
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 404
    Width = 660
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 564
      Top = 14
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
  end
  object pnlHost: TPanel
    Left = 0
    Top = 64
    Width = 660
    Height = 340
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
  end
end
