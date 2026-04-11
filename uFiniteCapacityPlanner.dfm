object frmFiniteCapacityPlanner: TfrmFiniteCapacityPlanner
  Left = 0
  Top = 0
  Caption = 'Planificador de Capacidad Finita'
  ClientHeight = 700
  ClientWidth = 1300
  Color = 15789544
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 17
  object splitter: TSplitter
    Left = 320
    Top = 51
    Width = 5
    Height = 649
    Color = 14737632
    ParentColor = False
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1300
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    object lblTitle: TLabel
      Left = 0
      Top = 0
      Width = 400
      Height = 50
      Align = alLeft
      AutoSize = False
      Caption = '  Planificador de Capacidad Finita'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ExplicitLeft = 16
    end
    object lblPendingCount: TLabel
      Left = 400
      Top = 0
      Width = 200
      Height = 50
      Align = alLeft
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      ExplicitLeft = 416
    end
    object pnlHeaderButtons: TPanel
      Left = 972
      Top = 0
      Width = 328
      Height = 50
      Align = alRight
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object btnCancelar: TButton
        Left = 144
        Top = 8
        Width = 88
        Height = 30
        Caption = 'Cancelar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnCancelarClick
      end
      object btnAceptar: TButton
        Left = 240
        Top = 8
        Width = 88
        Height = 30
        Caption = 'Aceptar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = btnAceptarClick
      end
    end
  end
  object pnlSeparator: TPanel
    Left = 0
    Top = 50
    Width = 1300
    Height = 1
    Align = alTop
    BevelOuter = bvNone
    Color = 14737632
    TabOrder = 1
  end
  object pnlPending: TPanel
    Left = 0
    Top = 51
    Width = 320
    Height = 649
    Align = alLeft
    BevelOuter = bvNone
    Color = 15263458
    TabOrder = 2
    object lblPendingTitle: TLabel
      Left = 0
      Top = 0
      Width = 320
      Height = 36
      Align = alTop
      AutoSize = False
      Caption = '   OT PENDIENTES'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object pnlSearch: TPanel
      Left = 0
      Top = 36
      Width = 320
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      Color = 15263458
      ParentBackground = False
      TabOrder = 0
      object lblSearchClear: TLabel
        Left = 290
        Top = 4
        Width = 24
        Height = 24
        Cursor = crHandPoint
        Alignment = taCenter
        AutoSize = False
        Caption = #215
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 10066329
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
        Visible = False
        OnClick = lblSearchClearClick
      end
      object edtSearch: TEdit
        Left = 8
        Top = 4
        Width = 280
        Height = 24
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 5592405
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        TextHint = 'Buscar OF, art'#237'culo, cliente...'
        OnChange = edtSearchChange
      end
    end
  end
  object pnlCentres: TPanel
    Left = 325
    Top = 51
    Width = 975
    Height = 649
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    TabOrder = 3
    object pnlHeaderCentres: TPanel
      Left = 0
      Top = 0
      Width = 975
      Height = 36
      Align = alTop
      BevelOuter = bvNone
      Color = 15789544
      ParentBackground = False
      TabOrder = 0
      object lblCentresTitle: TLabel
        Left = 0
        Top = 0
        Width = 289
        Height = 36
        Align = alLeft
        Caption = '   CENTROS DE TRABAJO - Capacidad Finita'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -14
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        ExplicitHeight = 19
      end
      object pnlFilterCentres: TPanel
        Left = 575
        Top = 0
        Width = 400
        Height = 36
        Align = alRight
        BevelOuter = bvNone
        Color = 15789544
        ParentBackground = False
        TabOrder = 0
        object lblFilterCaption: TLabel
          Left = 0
          Top = 0
          Width = 52
          Height = 36
          Align = alLeft
          AutoSize = False
          Caption = 'Centros:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitLeft = 8
        end
        object pnlFilterBtn: TPanel
          Left = 64
          Top = 4
          Width = 260
          Height = 28
          Cursor = crHandPoint
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          object lblFilterText: TLabel
            Left = 8
            Top = 0
            Width = 220
            Height = 28
            Cursor = crHandPoint
            AutoSize = False
            Caption = 'Todos los centros'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 5592405
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            Layout = tlCenter
          end
          object lblFilterArrow: TLabel
            Left = 236
            Top = 0
            Width = 20
            Height = 28
            Cursor = crHandPoint
            Alignment = taCenter
            AutoSize = False
            Caption = #9660
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 8947848
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            Layout = tlCenter
          end
        end
      end
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 672
    Width = 1300
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    Color = 15263458
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 8947848
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    object lblFooterPending: TLabel
      Left = 8
      Top = 0
      Width = 250
      Height = 28
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object lblFooterAssigned: TLabel
      Left = 270
      Top = 0
      Width = 250
      Height = 28
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object lblFooterHours: TLabel
      Left = 530
      Top = 0
      Width = 250
      Height = 28
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object lblFooterCapacity: TLabel
      Left = 790
      Top = 0
      Width = 250
      Height = 28
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
  end
end
