object frmNesting2D: TfrmNesting2D
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Nesting 2D - Encaje de piezas'
  ClientHeight = 800
  ClientWidth = 1400
  Color = 15790320
  Constraints.MinHeight = 620
  Constraints.MinWidth = 1000
  WindowState = wsMaximized
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseWheel = FormMouseWheel
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1400
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 7
      Width = 233
      Height = 25
      Caption = 'Nesting 2D - Encaje de piezas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 34
      Width = 372
      Height = 15
      Caption = 'Distribuye figuras en la planxa maximizando el aprovechamiento'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 56
    Width = 320
    Height = 744
    Align = alLeft
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 1
    object lblAncho: TLabel
      Left = 12
      Top = 12
      Width = 68
      Height = 15
      Caption = 'Ancho (mm)'
    end
    object edAncho: TcxSpinEdit
      Left = 12
      Top = 30
      Width = 140
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 0
      Value = 2000
    end
    object lblAlto: TLabel
      Left = 168
      Top = 12
      Width = 55
      Height = 15
      Caption = 'Alto (mm)'
    end
    object edAlto: TcxSpinEdit
      Left = 168
      Top = 30
      Width = 140
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 1
      Value = 1000
    end
    object lblKerf: TLabel
      Left = 12
      Top = 62
      Width = 92
      Height = 15
      Caption = 'Separaci'#243'n (mm)'
    end
    object edKerf: TcxSpinEdit
      Left = 12
      Top = 80
      Width = 140
      Height = 24
      Properties.MaxValue = 1000.000000000000000000
      TabOrder = 2
      Value = 3
    end
    object lblPaso: TLabel
      Left = 168
      Top = 62
      Width = 78
      Height = 15
      Caption = 'Paso (mm)'
    end
    object edPaso: TcxSpinEdit
      Left = 168
      Top = 80
      Width = 140
      Height = 24
      Properties.MaxValue = 1000.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 3
      Value = 5
    end
    object lblGravedad: TLabel
      Left = 12
      Top = 112
      Width = 87
      Height = 15
      Caption = 'Gravedad'
    end
    object cbGravedad: TcxComboBox
      Left = 12
      Top = 130
      Width = 140
      Height = 24
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 14
    end
    object lblOrden: TLabel
      Left = 168
      Top = 112
      Width = 87
      Height = 15
      Caption = 'Orden piezas'
    end
    object cbOrden: TcxComboBox
      Left = 168
      Top = 130
      Width = 140
      Height = 24
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 19
    end
    object lblMargenes: TLabel
      Left = 12
      Top = 160
      Width = 190
      Height = 15
      Caption = 'M'#225'rgenes I/D/S/I (mm, no aprovechar)'
    end
    object edMargIzq: TcxSpinEdit
      Left = 12
      Top = 178
      Width = 68
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      TabOrder = 15
      Value = 0
    end
    object edMargDer: TcxSpinEdit
      Left = 84
      Top = 178
      Width = 68
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      TabOrder = 16
      Value = 0
    end
    object edMargSup: TcxSpinEdit
      Left = 156
      Top = 178
      Width = 68
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      TabOrder = 17
      Value = 0
    end
    object edMargInf: TcxSpinEdit
      Left = 228
      Top = 178
      Width = 68
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      TabOrder = 18
      Value = 0
    end
    object lblForma: TLabel
      Left = 12
      Top = 210
      Width = 36
      Height = 15
      Caption = 'Forma'
    end
    object cbForma: TcxComboBox
      Left = 12
      Top = 228
      Width = 296
      Height = 24
      Properties.DropDownListStyle = lsFixedList
      Properties.OnChange = cbFormaPropertiesChange
      TabOrder = 4
    end
    object lblP1: TLabel
      Left = 12
      Top = 258
      Width = 61
      Height = 15
      Caption = 'Ancho (mm)'
    end
    object edP1: TcxSpinEdit
      Left = 12
      Top = 276
      Width = 140
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 5
      Value = 300
    end
    object lblP2: TLabel
      Left = 168
      Top = 258
      Width = 47
      Height = 15
      Caption = 'Alto (mm)'
    end
    object edP2: TcxSpinEdit
      Left = 168
      Top = 276
      Width = 140
      Height = 24
      Properties.MaxValue = 100000.000000000000000000
      TabOrder = 6
      Value = 200
    end
    object lblCant: TLabel
      Left = 12
      Top = 308
      Width = 51
      Height = 15
      Caption = 'Cantidad'
    end
    object edCant: TcxSpinEdit
      Left = 12
      Top = 326
      Width = 140
      Height = 24
      Properties.MinValue = 1.000000000000000000
      Properties.MaxValue = 1000.000000000000000000
      TabOrder = 7
      Value = 1
    end
    object lblVeta: TLabel
      Left = 168
      Top = 308
      Width = 27
      Height = 15
      Caption = 'Veta'
    end
    object cbVeta: TcxComboBox
      Left = 168
      Top = 326
      Width = 140
      Height = 24
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 8
    end
    object btnAddForma: TcxButton
      Left = 12
      Top = 360
      Width = 146
      Height = 28
      Caption = 'A'#241'adir forma'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 9
      OnClick = btnAddFormaClick
    end
    object btnPoligono: TcxButton
      Left = 162
      Top = 360
      Width = 146
      Height = 28
      Caption = 'Pol'#237'gono libre...'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 10
      OnClick = btnPoligonoClick
    end
    object btnImportDxf: TcxButton
      Left = 12
      Top = 392
      Width = 296
      Height = 28
      Caption = 'Importar DXF...'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 13
      OnClick = btnImportDxfClick
    end
    object gridPiezas: TcxGrid
      Left = 12
      Top = 426
      Width = 296
      Height = 224
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 11
      object tvPiezas: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        OnEditValueChanged = tvPiezasEditValueChanged
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
        object colPzNombre: TcxGridColumn
          Caption = 'Pieza'
          Options.Editing = False
          Width = 100
        end
        object colPzCantidad: TcxGridColumn
          Caption = 'Cant.'
          PropertiesClassName = 'TcxSpinEditProperties'
          Properties.MinValue = 1.000000000000000000
          Properties.MaxValue = 5000.000000000000000000
          Width = 50
        end
        object colPzArea: TcxGridColumn
          Caption = #193'rea'
          Options.Editing = False
          Width = 80
        end
        object colPzVeta: TcxGridColumn
          Caption = 'Veta'
          PropertiesClassName = 'TcxComboBoxProperties'
          Properties.DropDownListStyle = lsFixedList
          Properties.Items.Strings = (
            'Libre'
            '0/180'
            'Fija')
          Width = 70
        end
      end
      object lvPiezas: TcxGridLevel
        GridView = tvPiezas
      end
    end
    object btnDelPieza: TcxButton
      Left = 12
      Top = 656
      Width = 146
      Height = 28
      Anchors = [akLeft, akBottom]
      Caption = 'Quitar pieza'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 12
      OnClick = btnDelPiezaClick
    end
    object btnUp: TcxButton
      Left = 218
      Top = 656
      Width = 44
      Height = 28
      Anchors = [akLeft, akBottom]
      Caption = #9650
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 20
      OnClick = btnUpClick
    end
    object btnDown: TcxButton
      Left = 264
      Top = 656
      Width = 44
      Height = 28
      Anchors = [akLeft, akBottom]
      Caption = #9660
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 21
      OnClick = btnDownClick
    end
  end
  object pnlCanvas: TPanel
    Left = 320
    Top = 56
    Width = 1080
    Height = 744
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object pbCanvas: TPaintBox
      Left = 0
      Top = 0
      Width = 800
      Height = 584
      Align = alClient
      OnMouseDown = pbCanvasMouseDown
      OnMouseMove = pbCanvasMouseMove
      OnMouseUp = pbCanvasMouseUp
      OnPaint = pbCanvasPaint
      ExplicitLeft = 240
      ExplicitTop = 168
    end
    object pnlMetrics: TPanel
      Left = 0
      Top = 566
      Width = 800
      Height = 58
      Align = alBottom
      BevelOuter = bvNone
      Color = 15790320
      ParentBackground = False
      TabOrder = 0
      object lblMetrics: TLabel
        Left = 12
        Top = 4
        Width = 380
        Height = 50
        AutoSize = False
        Caption = 'Sin calcular.'
        WordWrap = True
      end
      object btnCerrar: TcxButton
        AlignWithMargins = True
        Margins.Left = 2
        Margins.Top = 8
        Margins.Right = 6
        Margins.Bottom = 8
        Left = 770
        Top = 8
        Width = 26
        Align = alRight
        Cancel = True
        Caption = 'X'
        LookAndFeel.Kind = lfOffice11
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2010Silver'
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.Flat = True
        TabOrder = 5
        OnClick = btnCerrarClick
      end
      object btnExportDxf: TcxButton
        AlignWithMargins = True
        Margins.Left = 2
        Margins.Top = 8
        Margins.Right = 2
        Margins.Bottom = 8
        Left = 726
        Top = 8
        Width = 40
        Align = alRight
        Caption = 'DXF'
        LookAndFeel.Kind = lfOffice11
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2010Silver'
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.Flat = True
        TabOrder = 4
        OnClick = btnExportDxfClick
      end
      object btnExportCSV: TcxButton
        AlignWithMargins = True
        Margins.Left = 2
        Margins.Top = 8
        Margins.Right = 2
        Margins.Bottom = 8
        Left = 682
        Top = 8
        Width = 40
        Align = alRight
        Caption = 'CSV'
        LookAndFeel.Kind = lfOffice11
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2010Silver'
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.Flat = True
        TabOrder = 3
        OnClick = btnExportCSVClick
      end
      object btnExportPNG: TcxButton
        AlignWithMargins = True
        Margins.Left = 2
        Margins.Top = 8
        Margins.Right = 2
        Margins.Bottom = 8
        Left = 638
        Top = 8
        Width = 40
        Align = alRight
        Caption = 'PNG'
        LookAndFeel.Kind = lfOffice11
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2010Silver'
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.Flat = True
        TabOrder = 2
        OnClick = btnExportPNGClick
      end
      object btnMaximo: TcxButton
        AlignWithMargins = True
        Margins.Left = 8
        Margins.Top = 8
        Margins.Right = 2
        Margins.Bottom = 8
        Left = 518
        Top = 8
        Width = 116
        Align = alRight
        Caption = 'M'#225'ximo que cabe'
        LookAndFeel.Kind = lfOffice11
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2010Silver'
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.Flat = True
        TabOrder = 1
        OnClick = btnMaximoClick
      end
      object btnCalcular: TcxButton
        AlignWithMargins = True
        Margins.Left = 2
        Margins.Top = 8
        Margins.Right = 2
        Margins.Bottom = 8
        Left = 412
        Top = 8
        Width = 102
        Align = alRight
        Caption = 'Calcular'
        LookAndFeel.Kind = lfOffice11
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Office2010Silver'
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.Flat = True
        TabOrder = 0
        OnClick = btnCalcularClick
      end
    end
  end
end
