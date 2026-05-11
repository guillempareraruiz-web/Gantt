object frmOrdenes: TfrmOrdenes
  Left = 0
  Top = 0
  Caption = #211'rdenes de Trabajo'
  ClientHeight = 600
  ClientWidth = 1100
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
    Width = 1100
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clHighlight
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 12
      Width = 174
      Height = 25
      Caption = #211'rdenes de Trabajo'
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
    Width = 1100
    Height = 497
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 600
      Top = 0
      Width = 5
      Height = 497
    end
    object sgOrdenes: TStringGrid
      Left = 0
      Top = 0
      Width = 600
      Height = 497
      Align = alLeft
      ColCount = 6
      DefaultRowHeight = 22
      FixedCols = 0
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
      TabOrder = 0
      OnClick = sgOrdenesClick
    end
    object pnlDetalle: TPanel
      Left = 605
      Top = 0
      Width = 495
      Height = 497
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object gbInfo: TGroupBox
        Left = 8
        Top = 4
        Width = 480
        Height = 180
        Caption = 'Datos de la orden'
        TabOrder = 0
        object lblCod: TLabel
          Left = 16
          Top = 24
          Width = 41
          Height = 15
          Caption = 'C'#243'digo:'
        end
        object lblDesc: TLabel
          Left = 200
          Top = 24
          Width = 70
          Height = 15
          Caption = 'Descripci'#243'n:'
        end
        object lblCentro: TLabel
          Left = 16
          Top = 64
          Width = 39
          Height = 15
          Caption = 'Centro:'
        end
        object lblPrioridad: TLabel
          Left = 200
          Top = 64
          Width = 53
          Height = 15
          Caption = 'Prioridad:'
        end
        object lblEstado: TLabel
          Left = 320
          Top = 64
          Width = 41
          Height = 15
          Caption = 'Estado:'
        end
        object lblCompromiso: TLabel
          Left = 16
          Top = 104
          Width = 73
          Height = 15
          Caption = 'Compromiso:'
        end
        object edtCod: TEdit
          Left = 16
          Top = 40
          Width = 170
          Height = 23
          ReadOnly = True
          TabOrder = 0
        end
        object edtDesc: TEdit
          Left = 200
          Top = 40
          Width = 270
          Height = 23
          ReadOnly = True
          TabOrder = 1
        end
        object edtCentro: TEdit
          Left = 16
          Top = 80
          Width = 170
          Height = 23
          ReadOnly = True
          TabOrder = 2
        end
        object edtPrioridad: TEdit
          Left = 200
          Top = 80
          Width = 100
          Height = 23
          ReadOnly = True
          TabOrder = 3
        end
        object edtEstado: TEdit
          Left = 320
          Top = 80
          Width = 150
          Height = 23
          ReadOnly = True
          TabOrder = 4
        end
        object edtCompromiso: TEdit
          Left = 16
          Top = 120
          Width = 170
          Height = 23
          ReadOnly = True
          TabOrder = 5
        end
      end
      object gbOperaciones: TGroupBox
        Left = 8
        Top = 190
        Width = 480
        Height = 300
        Caption = 'Operaciones de la orden'
        TabOrder = 1
        object sgOperaciones: TStringGrid
          Left = 8
          Top = 24
          Width = 463
          Height = 268
          Align = alCustom
          ColCount = 7
          DefaultRowHeight = 22
          FixedCols = 0
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
          TabOrder = 0
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 547
    Width = 1100
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCerrar: TButton
      Left = 990
      Top = 12
      Width = 90
      Height = 30
      Caption = 'Cerrar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
end
