object frmCardLayoutEditor: TfrmCardLayoutEditor
  Left = 0
  Top = 0
  Caption = 'Editor de Card Layout'
  ClientHeight = 640
  ClientWidth = 920
  Color = 15790320
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
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 158
      Height = 21
      Caption = 'Editor de Card Layout'
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
      Width = 295
      Height = 15
      Caption = 'Configura la distribuci'#243'n y contenido visual de los cards'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblTemplate: TLabel
      Left = 530
      Top = 10
      Width = 45
      Height = 15
      Caption = 'Plantilla:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cmbTemplate: TComboBox
      Left = 596
      Top = 7
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 1
      OnChange = cmbTemplateChange
    end
    object btnApplyTemplate: TButton
      Left = 804
      Top = 6
      Width = 100
      Height = 25
      Caption = 'Aplicar plantilla'
      TabOrder = 0
      OnClick = btnApplyTemplateClick
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
    object btnAceptar: TButton
      Left = 740
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Aceptar'
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TButton
      Left = 826
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
    object btnCargar: TButton
      Left = 16
      Top = 6
      Width = 90
      Height = 28
      Caption = 'Cargar...'
      TabOrder = 2
      OnClick = btnCargarClick
    end
    object btnGuardar: TButton
      Left = 112
      Top = 6
      Width = 90
      Height = 28
      Caption = 'Guardar...'
      TabOrder = 3
      OnClick = btnGuardarClick
    end
    object btnDefecto: TButton
      Left = 216
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Layout por defecto'
      TabOrder = 4
      OnClick = btnDefectoClick
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
    ParentBackground = False
    TabOrder = 2
    object splitter: TSplitter
      Left = 600
      Top = 0
      Width = 5
      Height = 550
      Align = alRight
      Color = 14540253
      ParentColor = False
    end
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 600
      Height = 550
      Align = alClient
      BevelOuter = bvNone
      Color = 15790320
      ParentBackground = False
      TabOrder = 0
      object pnlRowsHeader: TPanel
        Left = 0
        Top = 0
        Width = 600
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        Color = 15790320
        ParentBackground = False
        TabOrder = 0
        object lblRows: TLabel
          Left = 12
          Top = 8
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
        object btnAddRow: TButton
          Left = 464
          Top = 4
          Width = 60
          Height = 26
          Caption = '+ Fila'
          TabOrder = 0
          OnClick = btnAddRowClick
        end
        object btnDelRow: TButton
          Left = 530
          Top = 4
          Width = 60
          Height = 26
          Caption = '- Fila'
          TabOrder = 1
          OnClick = btnDelRowClick
        end
      end
      object pnlRowsArea: TPanel
        Left = 0
        Top = 36
        Width = 600
        Height = 514
        Align = alClient
        BevelOuter = bvNone
        Color = 15790320
        ParentBackground = False
        TabOrder = 1
        object boxRows: TScrollBox
          Left = 0
          Top = 0
          Width = 600
          Height = 514
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
      Left = 605
      Top = 0
      Width = 315
      Height = 550
      Align = alRight
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object pnlPreviewHeader: TPanel
        Left = 0
        Top = 0
        Width = 315
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblPreview: TLabel
          Left = 12
          Top = 8
          Width = 47
          Height = 17
          Caption = 'Preview'
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
        Width = 315
        Height = 254
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object pbPreview: TPaintBox
          Left = 12
          Top = 8
          Width = 290
          Height = 230
          OnPaint = pbPreviewPaint
        end
      end
      object pnlProps: TPanel
        Left = 0
        Top = 290
        Width = 315
        Height = 260
        Align = alBottom
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
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
        object lblLayoutName: TLabel
          Left = 12
          Top = 30
          Width = 47
          Height = 15
          Caption = 'Nombre:'
        end
        object lblCardHeight: TLabel
          Left = 12
          Top = 58
          Width = 61
          Height = 15
          Caption = 'Altura card:'
        end
        object lblPaddingH: TLabel
          Left = 12
          Top = 86
          Width = 59
          Height = 15
          Caption = 'Padding H:'
        end
        object lblPaddingV: TLabel
          Left = 160
          Top = 86
          Width = 57
          Height = 15
          Caption = 'Padding V:'
        end
        object lblCornerR: TLabel
          Left = 160
          Top = 58
          Width = 67
          Height = 15
          Caption = 'Radio borde:'
        end
        object edtName: TEdit
          Left = 90
          Top = 27
          Width = 210
          Height = 23
          TabOrder = 0
          OnChange = edtNameChange
        end
        object seCardHeight: TSpinEdit
          Left = 90
          Top = 55
          Width = 60
          Height = 24
          MaxValue = 300
          MinValue = 30
          TabOrder = 1
          Value = 88
          OnChange = seCardHeightChange
        end
        object sePaddingH: TSpinEdit
          Left = 90
          Top = 83
          Width = 50
          Height = 24
          MaxValue = 40
          MinValue = 0
          TabOrder = 2
          Value = 6
          OnChange = sePaddingHChange
        end
        object sePaddingV: TSpinEdit
          Left = 240
          Top = 83
          Width = 50
          Height = 24
          MaxValue = 40
          MinValue = 0
          TabOrder = 3
          Value = 6
          OnChange = sePaddingVChange
        end
        object seCornerRadius: TSpinEdit
          Left = 250
          Top = 55
          Width = 50
          Height = 24
          MaxValue = 30
          MinValue = 0
          TabOrder = 4
          Value = 6
          OnChange = seCornerRadiusChange
        end
      end
    end
  end
  object dlgOpen: TOpenDialog
    DefaultExt = 'cardlayout'
    Filter = 'Card Layout (*.cardlayout)|*.cardlayout|JSON (*.json)|*.json'
    Left = 456
    Top = 600
  end
  object dlgSave: TSaveDialog
    DefaultExt = 'cardlayout'
    Filter = 'Card Layout (*.cardlayout)|*.cardlayout|JSON (*.json)|*.json'
    Left = 504
    Top = 600
  end
end
