object frmGanttHistoryTimeline: TfrmGanttHistoryTimeline
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Historial de cambios'
  ClientHeight = 460
  ClientWidth = 360
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 360
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 10
      Width = 132
      Height = 19
      Caption = 'Historial de cambios'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblContador: TLabel
      Left = 16
      Top = 33
      Width = 92
      Height = 15
      Caption = 'Cambio 0 de 0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8421504
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object lstPasos: TListBox
    Left = 0
    Top = 56
    Width = 360
    Height = 360
    Style = lbOwnerDrawFixed
    Align = alClient
    BorderStyle = bsNone
    Color = clWindow
    ItemHeight = 44
    ParentColor = False
    TabOrder = 1
    OnClick = lstPasosClick
    OnDblClick = lstPasosDblClick
    OnDrawItem = lstPasosDrawItem
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 416
    Width = 360
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnDeshacer: TButton
      Left = 8
      Top = 8
      Width = 90
      Height = 28
      Caption = 'Deshacer'
      TabOrder = 0
      OnClick = btnDeshacerClick
    end
    object btnRehacer: TButton
      Left = 104
      Top = 8
      Width = 90
      Height = 28
      Caption = 'Rehacer'
      TabOrder = 1
      OnClick = btnRehacerClick
    end
    object btnCerrar: TButton
      Left = 262
      Top = 8
      Width = 90
      Height = 28
      Caption = 'Cerrar'
      TabOrder = 2
      OnClick = btnCerrarClick
    end
  end
end
