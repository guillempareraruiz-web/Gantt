object frmDemoPerfilDlg: TfrmDemoPerfilDlg
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Demostraci'#243'n a medida'
  ClientHeight = 700
  ClientWidth = 1120
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1120
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 20
      Top = 10
      Width = 214
      Height = 25
      Caption = 'Demostraci'#243'n a medida'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 20
      Top = 38
      Width = 520
      Height = 15
      Caption =
        'Elija el tipo de planta que m'#225's se parezca al cliente que va a vi' +
        'sitar'
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
    Top = 652
    Width = 1120
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnGenerar: TcxButton
      Left = 856
      Top = 10
      Width = 140
      Height = 30
      Caption = 'Generar demo'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 1004
      Top = 10
      Width = 96
      Height = 30
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
    object btnCarpeta: TcxButton
      Left = 20
      Top = 10
      Width = 190
      Height = 30
      Caption = 'Abrir carpeta de perfiles'
      TabOrder = 2
      OnClick = btnCarpetaClick
    end
    object lblPie: TLabel
      Left = 224
      Top = 17
      Width = 600
      Height = 15
      AutoSize = False
      Caption =
        'Copie un perfil y ed'#237'telo para crear el suyo: no hace falta reins' +
        'talar nada.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlIzq: TPanel
    Left = 0
    Top = 64
    Width = 300
    Height = 588
    Align = alLeft
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object lblPerfiles: TLabel
      Left = 20
      Top = 12
      Width = 88
      Height = 15
      Caption = 'Tipo de planta'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblNumPerfiles: TLabel
      Left = 20
      Top = 32
      Width = 260
      Height = 15
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lstPerfiles: TcxListBox
      Left = 20
      Top = 54
      Width = 264
      Height = 518
      ItemHeight = 22
      TabOrder = 0
      OnClick = lstPerfilesClick
    end
  end
  object pnlDer: TPanel
    Left = 300
    Top = 64
    Width = 820
    Height = 588
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblNombre: TLabel
      Left = 12
      Top = 12
      Width = 100
      Height = 25
      Caption = 'Perfil'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblDescripcion: TLabel
      Left = 12
      Top = 42
      Width = 796
      Height = 32
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object pnlFicha: TPanel
      Left = 12
      Top = 78
      Width = 796
      Height = 76
      BevelOuter = bvNone
      Color = 16053492
      ParentBackground = False
      TabOrder = 0
    end
    object lblLineas: TLabel
      Left = 12
      Top = 164
      Width = 200
      Height = 15
      Caption = 'C'#243'mo se ver'#225' el plan'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object pnlEsquema: TPanel
      Left = 12
      Top = 184
      Width = 796
      Height = 130
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
    end
    object lblRuta: TLabel
      Left = 12
      Top = 326
      Width = 200
      Height = 15
      Caption = 'Ruta de fabricaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblRutaDet: TLabel
      Left = 12
      Top = 346
      Width = 796
      Height = 18
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblArticulos: TLabel
      Left = 12
      Top = 374
      Width = 200
      Height = 15
      Caption = 'Art'#237'culos de ejemplo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object gridArticulos: TcxGrid
      Left = 12
      Top = 394
      Width = 796
      Height = 120
      TabOrder = 2
      object tvArticulos: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsSelection.CellSelect = False
        OptionsView.GroupByBox = False
        Styles.OnGetContentStyle = tvArticulosStylesGetContentStyle
        object colArtCodigo: TcxGridColumn
          Caption = 'C'#243'digo'
          Width = 110
        end
        object colArtDesc: TcxGridColumn
          Caption = 'Descripci'#243'n'
          Width = 400
        end
        object colArtSetup: TcxGridColumn
          Caption = 'Provoca cambio'
          Width = 250
        end
      end
      object lvlArticulos: TcxGridLevel
        GridView = tvArticulos
      end
    end
    object lblCantidad: TLabel
      Left = 12
      Top = 528
      Width = 130
      Height = 15
      Caption = 'Cu'#225'ntas '#243'rdenes generar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object seOrdenes: TcxSpinEdit
      Left = 12
      Top = 548
      Properties.MaxValue = 200.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 3
      Value = 18
      Width = 90
    end
    object lblOrdenesNota: TLabel
      Left = 112
      Top = 552
      Width = 400
      Height = 15
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object chkCrearSetup: TcxCheckBox
      Left = 520
      Top = 548
      Width = 290
      Height = 21
      Caption = 'Crear las reglas de tiempo de cambio'
      State = cbsChecked
      TabOrder = 4
      Transparent = True
    end
  end
end
