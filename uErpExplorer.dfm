object frmErpExplorer: TfrmErpExplorer
  Left = 0
  Top = 0
  Caption = 'Explorador ERP'
  ClientHeight = 700
  ClientWidth = 1100
  Color = clBtnFace
  Constraints.MinHeight = 500
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pgcMain: TcxPageControl
    Left = 0
    Top = 0
    Width = 1100
    Height = 645
    Align = alClient
    TabOrder = 0
    Properties.ActivePage = tabConfiguracion
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 643
    ClientRectLeft = 2
    ClientRectRight = 1098
    ClientRectTop = 25
    object tabConfiguracion: TcxTabSheet
      Caption = 'Configuraci'#243'n'
      object pnlErpActivo: TPanel
        Left = 0
        Top = 0
        Width = 1096
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblErpActivo: TLabel
          Left = 12
          Top = 10
          Width = 600
          Height = 18
          AutoSize = False
          Caption = 'ERP activo: ...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object pnlPruebaConexion: TPanel
        Left = 0
        Top = 568
        Width = 1096
        Height = 50
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 1
        object lblResultadoConexion: TLabel
          Left = 196
          Top = 16
          Width = 884
          Height = 18
          AutoSize = False
        end
        object btnProbarConexion: TButton
          Left = 12
          Top = 8
          Width = 170
          Height = 32
          Caption = 'Probar conexi'#243'n'
          TabOrder = 0
          OnClick = btnProbarConexionClick
        end
      end
      object pgcErpConfig: TcxPageControl
        Left = 0
        Top = 36
        Width = 1096
        Height = 532
        Align = alClient
        TabOrder = 2
        Properties.ActivePage = tabSage200
        Properties.CustomButtons.Buttons = <>
        Properties.HideTabs = True
        ClientRectBottom = 531
        ClientRectLeft = 1
        ClientRectRight = 1095
        ClientRectTop = 1
        object tabSage200: TcxTabSheet
          Caption = 'Sage 200'
          object pnlConexion: TGroupBox
            Left = 12
            Top = 12
            Width = 556
            Height = 200
            Caption = 'Conexi'#243'n SQL Server (Sage 200)'
            TabOrder = 0
            object lblServer: TLabel
              Left = 16
              Top = 28
              Width = 46
              Height = 15
              Caption = 'Servidor:'
            end
            object lblDatabase: TLabel
              Left = 16
              Top = 60
              Width = 75
              Height = 15
              Caption = 'Base de datos:'
            end
            object lblUserName: TLabel
              Left = 16
              Top = 124
              Width = 43
              Height = 15
              Caption = 'Usuario:'
            end
            object lblPassword: TLabel
              Left = 16
              Top = 156
              Width = 63
              Height = 15
              Caption = 'Contrase'#241'a:'
            end
            object edServer: TEdit
              Left = 120
              Top = 24
              Width = 420
              Height = 23
              TabOrder = 0
            end
            object edDatabase: TEdit
              Left = 120
              Top = 56
              Width = 420
              Height = 23
              TabOrder = 1
            end
            object chkWindowsAuth: TCheckBox
              Left = 120
              Top = 92
              Width = 250
              Height = 17
              Caption = 'Autenticaci'#243'n de Windows'
              TabOrder = 2
              OnClick = chkWindowsAuthClick
            end
            object edUserName: TEdit
              Left = 120
              Top = 120
              Width = 420
              Height = 23
              TabOrder = 3
            end
            object edPassword: TEdit
              Left = 120
              Top = 152
              Width = 420
              Height = 23
              PasswordChar = '*'
              TabOrder = 4
            end
          end
          object pnlEmpresa: TGroupBox
            Left = 12
            Top = 220
            Width = 556
            Height = 110
            Caption = 'Empresa del ERP'
            TabOrder = 1
            object lblCodigoEmpresa: TLabel
              Left = 16
              Top = 28
              Width = 106
              Height = 15
              Caption = 'C'#243'digo de empresa:'
            end
            object lblEjercicio: TLabel
              Left = 16
              Top = 60
              Width = 47
              Height = 15
              Caption = 'Ejercicio:'
            end
            object cmbCodigoEmpresa: TComboBox
              Left = 120
              Top = 24
              Width = 300
              Height = 23
              TabOrder = 0
            end
            object btnCargarEmpresas: TButton
              Left = 426
              Top = 23
              Width = 114
              Height = 25
              Caption = 'Cargar empresas'
              TabOrder = 1
              OnClick = btnCargarEmpresasClick
            end
            object edEjercicio: TEdit
              Left = 120
              Top = 56
              Width = 100
              Height = 23
              NumbersOnly = True
              TabOrder = 2
            end
          end
        end
        object tabErpProximamente: TcxTabSheet
          Caption = 'Pr'#243'ximamente'
          ImageIndex = 1
          object lblProximamente: TLabel
            Left = 0
            Top = 0
            Width = 1094
            Height = 530
            Align = alClient
            Alignment = taCenter
            Caption = 'Configuraci'#243'n para este ERP a'#250'n no implementada.'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -16
            Font.Name = 'Segoe UI'
            Font.Style = [fsItalic]
            ParentFont = False
            Layout = tlCenter
            ExplicitWidth = 359
            ExplicitHeight = 21
          end
        end
      end
    end
    object tabExplorador: TcxTabSheet
      Caption = 'Explorador'
      ImageIndex = 1
      object splitVertical: TSplitter
        Left = 220
        Top = 0
        Width = 6
        Height = 618
        ExplicitHeight = 617
      end
      object pnlEntidades: TPanel
        Left = 0
        Top = 0
        Width = 220
        Height = 618
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        DesignSize = (
          220
          618)
        object lblEntidades: TLabel
          Left = 8
          Top = 8
          Width = 54
          Height = 15
          Caption = 'Entidades:'
        end
        object lstEntidades: TListBox
          Left = 8
          Top = 28
          Width = 208
          Height = 552
          Anchors = [akLeft, akTop, akRight, akBottom]
          ItemHeight = 15
          TabOrder = 0
          OnClick = lstEntidadesClick
        end
      end
      object pnlExploradorDerecho: TPanel
        Left = 226
        Top = 0
        Width = 870
        Height = 618
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object pnlParametros: TPanel
          Left = 0
          Top = 0
          Width = 870
          Height = 70
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBotonesLeer: TPanel
            Left = 690
            Top = 0
            Width = 180
            Height = 70
            Align = alRight
            BevelOuter = bvNone
            TabOrder = 0
            object btnLeer: TButton
              Left = 8
              Top = 22
              Width = 80
              Height = 30
              Caption = 'Leer'
              Default = True
              TabOrder = 0
              OnClick = btnLeerClick
            end
            object btnLimpiar: TButton
              Left = 92
              Top = 22
              Width = 80
              Height = 30
              Caption = 'Limpiar'
              TabOrder = 1
              OnClick = btnLimpiarClick
            end
          end
          object pgcParametros: TcxPageControl
            Left = 0
            Top = 0
            Width = 690
            Height = 70
            Align = alClient
            TabOrder = 1
            Properties.ActivePage = tabParamNinguno
            Properties.CustomButtons.Buttons = <>
            Properties.HideTabs = True
            ClientRectBottom = 69
            ClientRectLeft = 1
            ClientRectRight = 689
            ClientRectTop = 1
            object tabParamNinguno: TcxTabSheet
              Caption = 'Ninguno'
            end
            object tabParamSerieNumEj: TcxTabSheet
              Caption = 'SerieNumEj'
              ImageIndex = 1
              object lblSerie: TLabel
                Left = 8
                Top = 8
                Width = 28
                Height = 15
                Caption = 'Serie:'
              end
              object lblNumero: TLabel
                Left = 100
                Top = 8
                Width = 47
                Height = 15
                Caption = 'N'#250'mero:'
              end
              object lblEjercicioP: TLabel
                Left = 220
                Top = 8
                Width = 47
                Height = 15
                Caption = 'Ejercicio:'
              end
              object edSerie: TEdit
                Left = 8
                Top = 28
                Width = 80
                Height = 23
                TabOrder = 0
              end
              object edNumero: TEdit
                Left = 100
                Top = 28
                Width = 110
                Height = 23
                NumbersOnly = True
                TabOrder = 1
              end
              object edEjercicioP: TEdit
                Left = 220
                Top = 28
                Width = 90
                Height = 23
                NumbersOnly = True
                TabOrder = 2
              end
            end
            object tabParamArtVer: TcxTabSheet
              Caption = 'ArtVer'
              ImageIndex = 2
              object lblArticulo: TLabel
                Left = 8
                Top = 8
                Width = 71
                Height = 15
                Caption = 'C'#243'd. art'#237'culo:'
              end
              object lblVersion: TLabel
                Left = 200
                Top = 8
                Width = 41
                Height = 15
                Caption = 'Versi'#243'n:'
              end
              object lblEjercicioStock: TLabel
                Left = 296
                Top = 8
                Width = 47
                Height = 15
                Caption = 'Ejercicio:'
                Visible = False
              end
              object edArticulo: TEdit
                Left = 8
                Top = 28
                Width = 180
                Height = 23
                TabOrder = 0
              end
              object edVersion: TEdit
                Left = 200
                Top = 28
                Width = 80
                Height = 23
                NumbersOnly = True
                TabOrder = 1
              end
              object seEjercicioStock: TcxSpinEdit
                Left = 296
                Top = 28
                Properties.AssignedValues.MinValue = True
                Properties.MaxValue = 9999.000000000000000000
                TabOrder = 2
                Visible = False
                Width = 80
              end
            end
            object tabParamFiltro: TcxTabSheet
              Caption = 'Filtro'
              ImageIndex = 3
              object lblFiltro: TLabel
                Left = 8
                Top = 8
                Width = 30
                Height = 15
                Caption = 'Filtro:'
              end
              object edFiltro: TEdit
                Left = 8
                Top = 28
                Width = 280
                Height = 23
                TabOrder = 0
                TextHint = 'Substring del c'#243'digo (vac'#237'o = todos)'
              end
            end
            object tabParamIdNum: TcxTabSheet
              Caption = 'IdNum'
              ImageIndex = 4
              object lblIdNum: TLabel
                Left = 8
                Top = 8
                Width = 14
                Height = 15
                Caption = 'ID:'
              end
              object edIdNum: TEdit
                Left = 8
                Top = 28
                Width = 110
                Height = 23
                NumbersOnly = True
                TabOrder = 0
              end
            end
            object tabParamFiltroFechas: TcxTabSheet
              Caption = 'FiltroFechas'
              ImageIndex = 5
              object lblFiltro2: TLabel
                Left = 8
                Top = 8
                Width = 75
                Height = 15
                Caption = 'Centro (filtro):'
              end
              object lblFechaDesde: TLabel
                Left = 220
                Top = 8
                Width = 68
                Height = 15
                Caption = 'Fecha desde:'
              end
              object lblFechaHasta: TLabel
                Left = 360
                Top = 8
                Width = 65
                Height = 15
                Caption = 'Fecha hasta:'
              end
              object edFiltro2: TEdit
                Left = 8
                Top = 28
                Width = 200
                Height = 23
                TabOrder = 0
                TextHint = 'Vac'#237'o = todos los centros'
              end
              object dtFechaDesde: TDateTimePicker
                Left = 220
                Top = 28
                Width = 130
                Height = 23
                Date = 46157.000000000000000000
                Time = 0.793702905095415200
                TabOrder = 1
              end
              object dtFechaHasta: TDateTimePicker
                Left = 360
                Top = 28
                Width = 130
                Height = 23
                Date = 46157.000000000000000000
                Time = 0.793702905095415200
                TabOrder = 2
              end
            end
          end
        end
        object pnlGridYMemo: TPanel
          Left = 0
          Top = 70
          Width = 870
          Height = 548
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 1
          object splitGridMemo: TSplitter
            Left = 0
            Top = 391
            Width = 870
            Height = 6
            Cursor = crVSplit
            Align = alBottom
            ExplicitTop = 400
            ExplicitWidth = 874
          end
          object grdResultados: TcxGrid
            Left = 0
            Top = 0
            Width = 870
            Height = 391
            Align = alClient
            TabOrder = 0
            object grdResultadosView: TcxGridDBTableView
              Navigator.Buttons.CustomButtons = <>
              ScrollbarAnnotations.CustomAnnotations = <>
              DataController.DataSource = dsResultados
              DataController.Summary.DefaultGroupSummaryItems = <>
              DataController.Summary.FooterSummaryItems = <>
              DataController.Summary.SummaryGroups = <>
              OptionsCustomize.ColumnsQuickCustomization = True
              OptionsData.Deleting = False
              OptionsData.Editing = False
              OptionsData.Inserting = False
              OptionsView.GroupByBox = False
            end
            object grdResultadosLevel: TcxGridLevel
              GridView = grdResultadosView
            end
          end
          object mmoLog: TMemo
            Left = 0
            Top = 397
            Width = 870
            Height = 151
            Align = alBottom
            Color = clBtnFace
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -12
            Font.Name = 'Consolas'
            Font.Style = []
            ParentFont = False
            ReadOnly = True
            ScrollBars = ssVertical
            TabOrder = 1
          end
        end
      end
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 645
    Width = 1100
    Height = 55
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      1100
      55)
    object btnGuardar: TButton
      Left = 884
      Top = 12
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Guardar'
      TabOrder = 0
      OnClick = btnGuardarClick
    end
    object btnCerrar: TButton
      Left = 990
      Top = 12
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
  object dsResultados: TDataSource
    DataSet = cdsResultados
    Left = 800
    Top = 200
  end
  object cdsResultados: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 800
    Top = 152
  end
end
