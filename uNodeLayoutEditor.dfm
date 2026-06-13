object frmNodeLayoutEditor: TfrmNodeLayoutEditor
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Dise'#241'ador de Nodos'
  ClientHeight = 640
  ClientWidth = 920
  Color = 15790320
  Constraints.MinHeight = 480
  Constraints.MinWidth = 760
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 920
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      920
      50)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 150
      Height = 21
      Caption = 'Dise'#241'ador de Nodos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 30
      Width = 301
      Height = 15
      Caption = 'Configura el contenido visual de los nodos por cada vista'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblSetName: TLabel
      Left = 200
      Top = 10
      Width = 4
      Height = 19
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -14
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object lblVista: TLabel
      Left = 686
      Top = 10
      Width = 28
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Vista:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cmbVista: TComboBox
      Left = 720
      Top = 7
      Width = 184
      Height = 23
      Style = csDropDownList
      Anchors = [akTop, akRight]
      DropDownCount = 20
      TabOrder = 0
      OnChange = cmbVistaChange
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 600
    Width = 920
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      920
      40)
    object btnAceptar: TButton
      Left = 704
      Top = 6
      Width = 116
      Height = 28
      Anchors = [akRight, akBottom]
      Caption = 'Guardar cambios'
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TButton
      Left = 826
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akRight, akBottom]
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 50
    Width = 920
    Height = 550
    Align = alClient
    BevelOuter = bvNone
    Color = 15790320
    Padding.Left = 12
    Padding.Top = 8
    Padding.Right = 12
    Padding.Bottom = 8
    ParentBackground = False
    TabOrder = 2
    object pnlLeft: TPanel
      AlignWithMargins = True
      Left = 12
      Top = 8
      Width = 572
      Height = 534
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 8
      Margins.Bottom = 0
      Align = alClient
      BevelOuter = bvNone
      Color = 15790320
      ParentBackground = False
      TabOrder = 0
      object pnlRowsHeader: TPanel
        Left = 0
        Top = 0
        Width = 572
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        Color = 15790320
        ParentBackground = False
        TabOrder = 0
        DesignSize = (
          572
          36)
        object lblRows: TLabel
          Left = 4
          Top = 10
          Width = 26
          Height = 17
          Caption = 'Filas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object btnAddRow: TLabel
          Left = 542
          Top = 6
          Width = 22
          Height = 25
          Cursor = crHandPoint
          Hint = 'Afegir fila'
          Anchors = [akTop, akRight]
          Caption = #10133
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12615680
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          OnClick = btnAddRowClick
        end
        object btnDelRow: TButton
          Left = 0
          Top = 0
          Width = 1
          Height = 1
          Caption = '- Fila'
          TabOrder = 0
          Visible = False
          OnClick = btnDelRowClick
        end
      end
      object pnlRowsArea: TPanel
        Left = 0
        Top = 36
        Width = 572
        Height = 498
        Align = alClient
        BevelOuter = bvNone
        Color = 15790320
        ParentBackground = False
        TabOrder = 1
        object boxRows: TScrollBox
          Left = 0
          Top = 0
          Width = 572
          Height = 498
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = 15790320
          ParentColor = False
          TabOrder = 0
        end
      end
    end
    object pnlRight: TPanel
      Left = 592
      Top = 8
      Width = 316
      Height = 534
      Align = alRight
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object pnlPreviewHeader: TPanel
        Left = 0
        Top = 0
        Width = 316
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblPreview: TLabel
          Left = 12
          Top = 8
          Width = 95
          Height = 17
          Caption = 'Previsualizaci'#243'n'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlPreviewArea: TPanel
        Left = 0
        Top = 36
        Width = 316
        Height = 180
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        DesignSize = (
          316
          180)
        object pbPreview: TPaintBox
          Left = 12
          Top = 8
          Width = 290
          Height = 156
          Anchors = [akLeft, akTop, akRight, akBottom]
          OnPaint = pbPreviewPaint
        end
      end
      object pnlProps: TPanel
        Left = 0
        Top = 216
        Width = 316
        Height = 318
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
        DesignSize = (
          316
          318)
        object lblProps: TLabel
          Left = 12
          Top = 4
          Width = 75
          Height = 17
          Caption = 'Propiedades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object vgProps: TcxVerticalGrid
          Left = 14
          Top = 28
          Width = 288
          Height = 282
          Anchors = [akLeft, akTop, akRight, akBottom]
          OptionsView.PaintStyle = psDelphi
          OptionsView.GridLineColor = 14540253
          OptionsView.RowHeaderWidth = 110
          OptionsBehavior.GoToNextCellOnEnter = True
          TabOrder = 0
          Version = 1
        end
      end
    end
  end
end
