object frmAsignaciones: TfrmAsignaciones
  Left = 0
  Top = 0
  Caption = 'Resultados de Planificaci'#243'n'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clHighlight
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 12
      Width = 257
      Height = 25
      Caption = 'Asignaciones de Planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlClient: TPanel
    Left = 0
    Top = 50
    Width = 900
    Height = 497
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object sgAsignaciones: TStringGrid
      Left = 0
      Top = 0
      Width = 900
      Height = 437
      Align = alClient
      ColCount = 8
      DefaultRowHeight = 22
      FixedCols = 0
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
      TabOrder = 0
    end
    object pnlInfo: TPanel
      Left = 0
      Top = 437
      Width = 900
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      Color = clInfoBk
      ParentBackground = False
      TabOrder = 1
      object lblTotalAsig: TLabel
        Left = 24
        Top = 18
        Width = 110
        Height = 19
        Caption = 'Asignaciones: 0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCosteTotal: TLabel
        Left = 280
        Top = 18
        Width = 130
        Height = 19
        Caption = 'Coste total: 0.00 €'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblScoreMedio: TLabel
        Left = 560
        Top = 18
        Width = 100
        Height = 19
        Caption = 'Score medio: -'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 547
    Width = 900
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnExportarTxt: TButton
      Left = 24
      Top = 12
      Width = 150
      Height = 30
      Caption = 'Exportar a CSV...'
      TabOrder = 0
      OnClick = btnExportarTxtClick
    end
    object btnCerrar: TButton
      Left = 790
      Top = 12
      Width = 90
      Height = 30
      Caption = 'Cerrar'
      Default = True
      ModalResult = 1
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
end
