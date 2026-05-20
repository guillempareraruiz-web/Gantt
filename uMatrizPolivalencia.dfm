object frmMatrizPolivalencia: TfrmMatrizPolivalencia
  Left = 0
  Top = 0
  Caption = 'Matriz de polivalencia'
  ClientHeight = 600
  ClientWidth = 1100
  Color = 16317660
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 250
      Height = 25
      Caption = 'Matriz de polivalencia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 38
      Width = 600
      Height = 15
      Caption = 'Qui pot hacer qu'#233' y en qu'#233' nivel. Detecta dependencias de una sola persona.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlLegend: TPanel
    Left = 0
    Top = 64
    Width = 1100
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 1
    object pbLegend: TPaintBox
      Left = 16
      Top = 8
      Width = 800
      Height = 28
      OnPaint = pbLegendPaint
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 560
    Width = 1100
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    Color = 16317660
    ParentBackground = False
    TabOrder = 2
    object lblFooter: TLabel
      Left = 16
      Top = 12
      Width = 700
      Height = 15
      Caption = 'Las columnas con un solo Referente (verde oscuro) y poca cobertura son tu riesgo: si esa persona falla, la operaci'#243'n queda parada.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 5526870
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnClose: TButton
      Left = 988
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object sbMatrix: TScrollBox
    Left = 0
    Top = 108
    Width = 1100
    Height = 452
    Align = alClient
    BorderStyle = bsNone
    Color = 16317660
    ParentColor = False
    TabOrder = 3
    object pbMatrix: TPaintBox
      Left = 0
      Top = 0
      Width = 1100
      Height = 452
      OnPaint = pbMatrixPaint
    end
  end
end
