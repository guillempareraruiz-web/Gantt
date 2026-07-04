object frmCentresKPI: TfrmCentresKPI
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Indicadores de Centros de Trabajo'
  ClientHeight = 800
  ClientWidth = 1120
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 340
    Height = 750
    Align = alLeft
    BevelOuter = bvNone
    Padding.Left = 14
    Padding.Top = 14
    Padding.Right = 14
    Padding.Bottom = 14
    TabOrder = 0
    object pnlCentroSel: TPanel
      Left = 14
      Top = 14
      Width = 312
      Height = 82
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblCentroCap: TLabel
        Left = 4
        Top = 8
        Width = 46
        Height = 15
        Caption = 'Centros:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnToggleAll: TButton
        Left = 228
        Top = 4
        Width = 80
        Height = 22
        Caption = 'Todos'
        TabOrder = 1
        OnClick = btnToggleAllClick
      end
      object cbCentros: TcxCheckComboBox
        Left = 4
        Top = 32
        Properties.EmptySelectionText = 'Ningun centro seleccionado'
        Properties.Items = <>
        Properties.OnEditValueChanged = cbCentrosChange
        TabOrder = 0
        Width = 304
      end
    end
    object pnlInfo: TPanel
      Left = 14
      Top = 104
      Width = 312
      Height = 632
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lblTituloInfo: TLabel
        Left = 8
        Top = 8
        Width = 91
        Height = 17
        Caption = 'Info del centro'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4210752
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
  end
  object PageControl1: TPageControl
    Left = 340
    Top = 0
    Width = 780
    Height = 750
    ActivePage = tsBloqueA
    Align = alClient
    TabOrder = 1
    object tsBloqueA: TTabSheet
      Caption = '  A - Ventana visible  '
    end
    object tsBloqueB: TTabSheet
      Caption = '  B - Ahora - Fin Gantt  '
      ImageIndex = 1
    end
    object tsBloqueC: TTabSheet
      Caption = '  C - Todo el Gantt  '
      ImageIndex = 2
    end
    object tsBloqueD: TTabSheet
      Caption = '  D - Fecha personalizada  '
      ImageIndex = 3
      object pnlFechaD: TPanel
        Left = 0
        Top = 0
        Width = 772
        Height = 44
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblDesdeD: TLabel
          Left = 14
          Top = 14
          Width = 41
          Height = 15
          Caption = 'Desde:'
        end
        object lblHastaD: TLabel
          Left = 232
          Top = 14
          Width = 38
          Height = 15
          Caption = 'Hasta:'
        end
        object dtDesdeD: TDateTimePicker
          Left = 62
          Top = 10
          Width = 150
          Height = 23
          Date = 46204.000000000000000000
          Time = 46204.000000000000000000
          TabOrder = 0
          OnChange = FechaDChange
        end
        object dtHastaD: TDateTimePicker
          Left = 276
          Top = 10
          Width = 150
          Height = 23
          Date = 46234.000000000000000000
          Time = 46234.000000000000000000
          TabOrder = 1
          OnChange = FechaDChange
        end
      end
    end
  end
end
