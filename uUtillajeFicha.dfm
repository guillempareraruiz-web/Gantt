object frmUtillajeFicha: TfrmUtillajeFicha
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Ficha de utillaje'
  ClientHeight = 620
  ClientWidth = 760
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 60
      Height = 25
      Caption = 'Utillaje'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 36
      Width = 3
      Height = 15
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 580
    Width = 760
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnOK: TButton
      Left = 544
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Guardar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 652
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object pc: TcxPageControl
    Left = 0
    Top = 60
    Width = 760
    Height = 520
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tsDatos
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 516
    ClientRectLeft = 4
    ClientRectRight = 756
    ClientRectTop = 26
    object tsDatos: TcxTabSheet
      Caption = 'Datos generales'
      ImageIndex = 0
      object lblCodigo: TLabel
        Left = 20
        Top = 20
        Width = 39
        Height = 15
        Caption = 'C'#243'digo'
      end
      object lblDescripcion: TLabel
        Left = 20
        Top = 52
        Width = 62
        Height = 15
        Caption = 'Descripci'#243'n'
      end
      object lblTipo: TLabel
        Left = 20
        Top = 84
        Width = 23
        Height = 15
        Caption = 'Tipo'
      end
      object lblFabricante: TLabel
        Left = 20
        Top = 116
        Width = 55
        Height = 15
        Caption = 'Fabricante'
      end
      object lblNumeroSerie: TLabel
        Left = 20
        Top = 148
        Width = 57
        Height = 15
        Caption = 'N'#186' de serie'
      end
      object lblAnyo: TLabel
        Left = 20
        Top = 180
        Width = 100
        Height = 15
        Caption = 'A'#241'o de fabricaci'#243'n'
      end
      object lblUbicacion: TLabel
        Left = 20
        Top = 220
        Width = 53
        Height = 15
        Caption = 'Ubicaci'#243'n'
      end
      object lblCentroActual: TLabel
        Left = 20
        Top = 252
        Width = 71
        Height = 15
        Caption = 'Centro actual'
      end
      object lblEstado: TLabel
        Left = 20
        Top = 284
        Width = 35
        Height = 15
        Caption = 'Estado'
      end
      object lblCantidad: TLabel
        Left = 20
        Top = 324
        Width = 57
        Height = 15
        Caption = 'Ejemplares'
      end
      object lblCantidadHint: TLabel
        Left = 140
        Top = 346
        Width = 290
        Height = 28
        AutoSize = False
        Caption = 
          'N'#186' de unidades intercambiables. 1 = uso exclusivo (dos operacion' +
          'es a la vez = conflicto).'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        WordWrap = True
      end
      object lblOrden: TLabel
        Left = 20
        Top = 466
        Width = 33
        Height = 15
        Caption = 'Orden'
      end
      object lblObservaciones: TLabel
        Left = 460
        Top = 20
        Width = 77
        Height = 15
        Caption = 'Observaciones'
      end
      object edCodigo: TcxTextEdit
        Left = 140
        Top = 16
        TabOrder = 0
        Width = 180
      end
      object edDescripcion: TcxTextEdit
        Left = 140
        Top = 48
        TabOrder = 1
        Width = 290
      end
      object edTipo: TcxTextEdit
        Left = 140
        Top = 80
        TabOrder = 2
        Width = 180
      end
      object edFabricante: TcxTextEdit
        Left = 140
        Top = 112
        TabOrder = 3
        Width = 290
      end
      object edNumeroSerie: TcxTextEdit
        Left = 140
        Top = 144
        TabOrder = 4
        Width = 180
      end
      object edAnyo: TcxSpinEdit
        Left = 140
        Top = 176
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 2100.000000000000000000
        TabOrder = 5
        Width = 90
      end
      object edUbicacion: TcxTextEdit
        Left = 140
        Top = 216
        TabOrder = 6
        Width = 290
      end
      object cbCentroActual: TcxComboBox
        Left = 140
        Top = 248
        Properties.DropDownListStyle = lsFixedList
        TabOrder = 7
        Width = 290
      end
      object cbEstado: TcxComboBox
        Left = 140
        Top = 280
        Properties.DropDownListStyle = lsFixedList
        TabOrder = 8
        Width = 180
      end
      object edCantidad: TcxSpinEdit
        Left = 140
        Top = 320
        Properties.MaxValue = 999.000000000000000000
        Properties.MinValue = 1.000000000000000000
        TabOrder = 9
        Value = 1
        Width = 90
      end
      object chkDisponible: TcxCheckBox
        Left = 138
        Top = 384
        Caption = 'Disponible (marca manual del usuario)'
        TabOrder = 10
      end
      object chkDisponiblePlan: TcxCheckBox
        Left = 138
        Top = 408
        Caption = 'Disponible para planificar'
        TabOrder = 11
      end
      object chkActivo: TcxCheckBox
        Left = 138
        Top = 432
        Caption = 'Activo (desmarcar para retirar sin borrar)'
        TabOrder = 12
      end
      object edOrden: TcxSpinEdit
        Left = 140
        Top = 462
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 9999.000000000000000000
        TabOrder = 13
        Width = 90
      end
      object memObservaciones: TMemo
        Left = 460
        Top = 40
        Width = 280
        Height = 300
        ScrollBars = ssVertical
        TabOrder = 14
      end
    end
    object tsVida: TcxTabSheet
      Caption = 'Vida '#250'til y tiempos'
      ImageIndex = 1
      object lblUnidadVida: TLabel
        Left = 20
        Top = 24
        Width = 58
        Height = 15
        Caption = 'Se mide en'
      end
      object lblVidaTotal: TLabel
        Left = 20
        Top = 60
        Width = 70
        Height = 15
        Caption = 'Vida '#250'til total'
      end
      object lblVidaHint: TLabel
        Left = 312
        Top = 60
        Width = 231
        Height = 13
        Caption = '0 = no se controla la vida '#250'til de este utillaje.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblContador: TLabel
        Left = 20
        Top = 96
        Width = 85
        Height = 15
        Caption = 'Contador actual'
      end
      object lblConsumo: TLabel
        Left = 160
        Top = 132
        Width = 118
        Height = 15
        Caption = 'Sin control de vida '#250'til'
      end
      object lblProxMant: TLabel
        Left = 20
        Top = 200
        Width = 130
        Height = 15
        Caption = 'Pr'#243'ximo mantenimiento'
      end
      object lblTiempos: TLabel
        Left = 20
        Top = 250
        Width = 180
        Height = 17
        Caption = 'Tiempos de cambio (minutos)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblTMontaje: TLabel
        Left = 20
        Top = 286
        Width = 44
        Height = 15
        Caption = 'Montaje'
      end
      object lblTDesmontaje: TLabel
        Left = 20
        Top = 318
        Width = 63
        Height = 15
        Caption = 'Desmontaje'
      end
      object lblTAjuste: TLabel
        Left = 20
        Top = 350
        Width = 33
        Height = 15
        Caption = 'Ajuste'
      end
      object cbUnidadVida: TcxComboBox
        Left = 160
        Top = 20
        Properties.DropDownListStyle = lsFixedList
        TabOrder = 0
        Width = 140
      end
      object edVidaTotal: TcxSpinEdit
        Left = 160
        Top = 56
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 999999999.000000000000000000
        Properties.OnChange = edVidaTotalChange
        TabOrder = 1
        Width = 140
      end
      object edContador: TcxSpinEdit
        Left = 160
        Top = 92
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 999999999.000000000000000000
        Properties.OnChange = edContadorChange
        TabOrder = 2
        Width = 140
      end
      object pbVida: TcxProgressBar
        Left = 160
        Top = 152
        Properties.BeginColor = 3947580
        Properties.EndColor = 3947580
        TabOrder = 3
        Width = 400
      end
      object dtProxMant: TcxDateEdit
        Left = 160
        Top = 196
        TabOrder = 4
        Width = 140
      end
      object chkSinMant: TcxCheckBox
        Left = 312
        Top = 195
        Caption = 'Sin fecha prevista'
        TabOrder = 5
        OnClick = chkSinMantClick
      end
      object edTMontaje: TcxSpinEdit
        Left = 160
        Top = 282
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 99999.000000000000000000
        TabOrder = 6
        Width = 100
      end
      object edTDesmontaje: TcxSpinEdit
        Left = 160
        Top = 314
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 99999.000000000000000000
        TabOrder = 7
        Width = 100
      end
      object edTAjuste: TcxSpinEdit
        Left = 160
        Top = 346
        Properties.AssignedValues.MinValue = True
        Properties.MaxValue = 99999.000000000000000000
        TabOrder = 8
        Width = 100
      end
    end
    object tsRelaciones: TcxTabSheet
      Caption = 'Relaciones'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lblCentros: TLabel
        Left = 16
        Top = 12
        Width = 228
        Height = 15
        Caption = 'Centros donde puede montarse este utillaje'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblOperaciones: TLabel
        Left = 16
        Top = 184
        Width = 204
        Height = 15
        Caption = 'Operaciones que requieren este utillaje'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblArticulos: TLabel
        Left = 16
        Top = 340
        Width = 185
        Height = 15
        Caption = 'Art'#237'culos que requieren este utillaje'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object gridCentros: TcxGrid
        Left = 16
        Top = 32
        Width = 726
        Height = 140
        TabOrder = 0
        object tvCentros: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsCustomize.ColumnSorting = False
          OptionsData.Deleting = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          object colCenId: TcxGridColumn
            Caption = 'CenterId'
            Visible = False
            Options.Editing = False
          end
          object colCenAsig: TcxGridColumn
            Caption = 'Asignado'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Width = 70
          end
          object colCenNombre: TcxGridColumn
            Caption = 'Centro'
            Options.Editing = False
            Width = 320
          end
          object colCenPref: TcxGridColumn
            Caption = 'Preferente'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Width = 80
          end
          object colCenTiempo: TcxGridColumn
            Caption = 'T. montaje espec'#237'fico (min)'
            PropertiesClassName = 'TcxSpinEditProperties'
            Properties.AssignedValues.MinValue = True
            Properties.MaxValue = 99999.000000000000000000
            Width = 180
          end
        end
        object lvCentros: TcxGridLevel
          GridView = tvCentros
        end
      end
      object btnOpAdd: TButton
        Left = 580
        Top = 180
        Width = 75
        Height = 24
        Caption = 'A'#241'adir'
        TabOrder = 1
        OnClick = btnOpAddClick
      end
      object btnOpDel: TButton
        Left = 664
        Top = 180
        Width = 78
        Height = 24
        Caption = 'Quitar'
        TabOrder = 2
        OnClick = btnOpDelClick
      end
      object gridOper: TcxGrid
        Left = 16
        Top = 208
        Width = 726
        Height = 120
        TabOrder = 3
        object tvOper: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsCustomize.ColumnSorting = False
          OptionsData.Deleting = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          object colOpCodigo: TcxGridColumn
            Caption = 'Operaci'#243'n'
            PropertiesClassName = 'TcxButtonEditProperties'
            Properties.Buttons = <
              item
                Default = True
                Kind = bkEllipsis
              end>
            Properties.OnButtonClick = colOpCodigoButtonClick
            Width = 300
          end
          object colOpObl: TcxGridColumn
            Caption = 'Obligatorio'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Width = 80
          end
          object colOpObs: TcxGridColumn
            Caption = 'Observaciones'
            Width = 330
          end
        end
        object lvOper: TcxGridLevel
          GridView = tvOper
        end
      end
      object btnArtAdd: TButton
        Left = 580
        Top = 336
        Width = 75
        Height = 24
        Caption = 'A'#241'adir'
        TabOrder = 4
        OnClick = btnArtAddClick
      end
      object btnArtDel: TButton
        Left = 664
        Top = 336
        Width = 78
        Height = 24
        Caption = 'Quitar'
        TabOrder = 5
        OnClick = btnArtDelClick
      end
      object gridArt: TcxGrid
        Left = 16
        Top = 364
        Width = 726
        Height = 120
        TabOrder = 6
        object tvArt: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsCustomize.ColumnSorting = False
          OptionsData.Deleting = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          object colArtCodigo: TcxGridColumn
            Caption = 'Art'#237'culo'
            PropertiesClassName = 'TcxButtonEditProperties'
            Properties.Buttons = <
              item
                Default = True
                Kind = bkEllipsis
              end>
            Properties.OnButtonClick = colArtCodigoButtonClick
            Width = 300
          end
          object colArtObl: TcxGridColumn
            Caption = 'Obligatorio'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Width = 80
          end
          object colArtObs: TcxGridColumn
            Caption = 'Observaciones'
            Width = 330
          end
        end
        object lvArt: TcxGridLevel
          GridView = tvArt
        end
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    SkinName = 'Office2019Colorful'
    Left = 700
    Top = 12
  end
end
