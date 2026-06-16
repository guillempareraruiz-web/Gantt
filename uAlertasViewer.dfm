object frmAlertasViewer: TfrmAlertasViewer
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Alertas de planificaci'#243'n'
  ClientHeight = 567
  ClientWidth = 924
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 19
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 924
    Height = 66
    Align = alTop
    BevelOuter = bvNone
    Color = 8776698
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 12
      Top = 10
      Width = 180
      Height = 21
      Caption = 'Alertas de planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSalud: TLabel
      Left = 12
      Top = 38
      Width = 88
      Height = 17
      Caption = 'Salud del plan'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnVerTodas: TButton
      AlignWithMargins = True
      Left = 789
      Top = 18
      Width = 124
      Height = 30
      Margins.Left = 4
      Margins.Top = 18
      Margins.Right = 11
      Margins.Bottom = 18
      Align = alRight
      Caption = 'Ver todas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnVerTodasClick
    end
    object btnConfig: TButton
      AlignWithMargins = True
      Left = 655
      Top = 18
      Width = 126
      Height = 30
      Margins.Left = 4
      Margins.Top = 18
      Margins.Right = 4
      Margins.Bottom = 18
      Align = alRight
      Caption = 'Configurar...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = btnConfigClick
    end
  end
  object lvAlertas: TcxListView
    Left = 0
    Top = 66
    Width = 924
    Height = 452
    Align = alClient
    Columns = <
      item
        Width = 40
      end
      item
        Caption = 'C'#243'd.'
        Width = 52
      end
      item
        Alignment = taRightJustify
        Caption = 'Peso'
        Width = 52
      end
      item
        Alignment = taRightJustify
        Caption = 'N'
        Width = 56
      end
      item
        AutoSize = True
        Caption = 'Alerta'
      end>
    HideSelection = False
    OwnerDraw = True
    ParentShowHint = False
    ReadOnly = True
    RowSelect = True
    ShowHint = True
    SmallImages = ilSeveridad
    TabOrder = 1
    ViewStyle = vsReport
    OnColumnClick = lvAlertasColumnClick
    OnDblClick = lvAlertasDblClick
    OnDrawItem = lvAlertasDrawItem
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 518
    Width = 924
    Height = 49
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblResumen: TLabel
      AlignWithMargins = True
      Left = 12
      Top = 0
      Width = 3
      Height = 49
      Margins.Left = 12
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alLeft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      ExplicitHeight = 13
    end
    object btnFiltrar: TButton
      AlignWithMargins = True
      Left = 707
      Top = 9
      Width = 100
      Height = 31
      Margins.Left = 4
      Margins.Top = 9
      Margins.Right = 4
      Margins.Bottom = 9
      Align = alRight
      Caption = 'Ver en Gantt'
      TabOrder = 0
      OnClick = btnFiltrarClick
    end
    object btnCerrar: TButton
      AlignWithMargins = True
      Left = 815
      Top = 9
      Width = 98
      Height = 31
      Margins.Left = 4
      Margins.Top = 9
      Margins.Right = 11
      Margins.Bottom = 9
      Align = alRight
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
  object ilSeveridad: TImageList
    Height = 26
    Width = 26
    Left = 24
    Top = 96
  end
end
