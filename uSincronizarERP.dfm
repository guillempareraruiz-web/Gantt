object frmSincronizarERP: TfrmSincronizarERP
  Left = 0
  Top = 0
  Caption = 'Sincronizar con ERP'
  ClientHeight = 620
  ClientWidth = 1280
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1280
      64)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 169
      Height = 25
      Caption = 'Sincronizar con ERP'
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
      Width = 371
      Height = 15
      Caption = 
        'Importa centros y m'#225'quinas del ERP a la base de datos del planif' +
        'icador'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblErpSistema: TLabel
      Left = 900
      Top = 22
      Width = 360
      Height = 19
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'ERP: -'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 64
    Width = 1280
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      1280
      44)
    object btnPreview: TButton
      Left = 12
      Top = 8
      Width = 140
      Height = 28
      Caption = 'Previsualizar'
      TabOrder = 0
      OnClick = btnPreviewClick
    end
    object btnSync: TButton
      Left = 158
      Top = 8
      Width = 180
      Height = 28
      Caption = 'Sincronizar seleccionados'
      TabOrder = 1
      OnClick = btnSyncClick
    end
    object lblCalRango: TLabel
      Left = 360
      Top = 14
      Width = 140
      Height = 15
      Caption = 'Calendarios - rango:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object dtCalDesde: TcxDateEdit
      Left = 500
      Top = 10
      Width = 110
      TabOrder = 3
    end
    object dtCalHasta: TcxDateEdit
      Left = 620
      Top = 10
      Width = 110
      TabOrder = 4
    end
    object btnHelp: TButton
      Left = 1240
      Top = 8
      Width = 28
      Height = 28
      Anchors = [akTop, akRight]
      Caption = '?'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnHelpClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 580
    Width = 1280
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      1280
      40)
    object lblSummary: TLabel
      Left = 12
      Top = 12
      Width = 311
      Height = 15
      Caption = 'Pulsa "Previsualizar" para comparar el ERP con la base local'
    end
    object btnClose: TButton
      Left = 1170
      Top = 6
      Width = 100
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pc: TcxPageControl
    Left = 0
    Top = 108
    Width = 1280
    Height = 472
    Align = alClient
    TabOrder = 3
    Properties.ActivePage = tabMaquinas
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 468
    ClientRectLeft = 4
    ClientRectRight = 1276
    ClientRectTop = 26
    object tabResumen: TcxTabSheet
      Caption = 'Resumen'
      object gridResumen: TcxGrid
        Left = 0
        Top = 0
        Width = 1272
        Height = 442
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvResumen: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <
            item
              Format = '0'
              Kind = skSum
              Column = colRNuevos
            end
            item
              Format = '0'
              Kind = skSum
              Column = colRActualizados
            end
            item
              Format = '0'
              Kind = skSum
              Column = colRSinCambios
            end
            item
              Format = '0'
              Kind = skSum
              Column = colRConflictos
            end
            item
              Format = '0'
              Kind = skSum
              Column = colREliminados
            end
            item
              Format = '0'
              Kind = skSum
              Column = colRTotal
            end>
          DataController.Summary.SummaryGroups = <>
          OptionsCustomize.ColumnFiltering = False
          OptionsCustomize.ColumnMoving = False
          OptionsCustomize.ColumnSorting = False
          OptionsData.Editing = False
          OptionsSelection.CellSelect = False
          OptionsView.DataRowHeight = 36
          OptionsView.Footer = True
          OptionsView.GroupByBox = False
          OptionsView.HeaderHeight = 36
          Styles.OnGetContentStyle = tvResumenStylesGetContentStyle
          object colREntidad: TcxGridColumn
            Caption = 'Entidad'
            HeaderAlignmentHorz = taCenter
            Width = 180
          end
          object colRNuevos: TcxGridColumn
            Caption = 'Nuevos'
            DataBinding.ValueType = 'Integer'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.Alignment.Horz = taLeftJustify
            HeaderAlignmentHorz = taCenter
            Width = 160
          end
          object colRActualizados: TcxGridColumn
            Caption = 'Actualizados'
            DataBinding.ValueType = 'Integer'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.Alignment.Horz = taLeftJustify
            HeaderAlignmentHorz = taCenter
            Width = 160
          end
          object colRSinCambios: TcxGridColumn
            Caption = 'Sin cambios'
            DataBinding.ValueType = 'Integer'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.Alignment.Horz = taLeftJustify
            HeaderAlignmentHorz = taCenter
            Width = 160
          end
          object colRConflictos: TcxGridColumn
            Caption = 'Conflictos'
            DataBinding.ValueType = 'Integer'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.Alignment.Horz = taLeftJustify
            HeaderAlignmentHorz = taCenter
            Width = 160
          end
          object colREliminados: TcxGridColumn
            Caption = 'Eliminados ERP'
            DataBinding.ValueType = 'Integer'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.Alignment.Horz = taLeftJustify
            HeaderAlignmentHorz = taCenter
            Width = 180
          end
          object colRTotal: TcxGridColumn
            Caption = 'TOTAL'
            DataBinding.ValueType = 'Integer'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.Alignment.Horz = taLeftJustify
            HeaderAlignmentHorz = taCenter
            Width = 160
          end
        end
        object lvResumen: TcxGridLevel
          GridView = tvResumen
        end
      end
    end
    object tabCentros: TcxTabSheet
      Caption = 'Centros de trabajo'
      object gridCentros: TcxGrid
        Left = 0
        Top = 0
        Width = 1272
        Height = 442
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvCentros: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsBehavior.IncSearch = True
          OptionsSelection.CellSelect = False
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvCentrosStylesGetContentStyle
          object colCEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colCCodigo: TcxGridColumn
            Caption = 'C'#243'digo ERP'
            Options.Editing = False
            Width = 110
          end
          object colCDescripcion: TcxGridColumn
            Caption = 'Descripci'#243'n ERP'
            Options.Editing = False
            Width = 220
          end
          object colCLocalTitulo: TcxGridColumn
            Caption = 'Local: T'#237'tulo'
            Options.Editing = False
            Width = 220
          end
          object colCConcurrencia: TcxGridColumn
            Caption = 'Concurrencia'
            Options.Editing = False
            Width = 100
          end
          object colCMaquinas: TcxGridColumn
            Caption = 'M'#225'quinas'
            Options.Editing = False
            Width = 80
          end
          object colCCoste: TcxGridColumn
            Caption = 'Coste/h'
            Options.Editing = False
            Width = 80
          end
          object colCGrupoHorario: TcxGridColumn
            Caption = 'Grupo horario'
            Options.Editing = False
            Width = 100
          end
          object colCAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 160
          end
        end
        object lvCentros: TcxGridLevel
          GridView = tvCentros
        end
      end
    end
    object tabMaquinas: TcxTabSheet
      Caption = 'M'#225'quinas'
      object gridMaquinas: TcxGrid
        Left = 0
        Top = 0
        Width = 1272
        Height = 442
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvMaquinas: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsBehavior.IncSearch = True
          OptionsSelection.CellSelect = False
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvMaquinasStylesGetContentStyle
          object colMEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colMCodigo: TcxGridColumn
            Caption = 'C'#243'digo ERP'
            Options.Editing = False
            Width = 110
          end
          object colMMarca: TcxGridColumn
            Caption = 'Marca'
            Options.Editing = False
            Width = 130
          end
          object colMModelo: TcxGridColumn
            Caption = 'Modelo'
            Options.Editing = False
            Width = 130
          end
          object colMDescripcion: TcxGridColumn
            Caption = 'Descripci'#243'n'
            Options.Editing = False
            Width = 240
          end
          object colMCoste: TcxGridColumn
            Caption = 'Coste/h'
            Options.Editing = False
            Width = 80
          end
          object colMUnidHora: TcxGridColumn
            Caption = 'Unidades/h'
            Options.Editing = False
            Width = 90
          end
          object colMLocalCodigo: TcxGridColumn
            Caption = 'Local: C'#243'digo'
            Options.Editing = False
            Width = 110
          end
          object colMAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 160
          end
        end
        object lvMaquinas: TcxGridLevel
          GridView = tvMaquinas
        end
      end
    end
    object tabOperarios: TcxTabSheet
      Caption = 'Operarios'
      object gridOperarios: TcxGrid
        Left = 0
        Top = 0
        Width = 1272
        Height = 442
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvOperarios: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsBehavior.IncSearch = True
          OptionsSelection.CellSelect = False
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvOperariosStylesGetContentStyle
          object colOEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colOCodigo: TcxGridColumn
            Caption = 'C'#243'digo ERP'
            Options.Editing = False
            Width = 90
          end
          object colONombre: TcxGridColumn
            Caption = 'Nombre'
            Options.Editing = False
            Width = 220
          end
          object colOCargo: TcxGridColumn
            Caption = 'Cargo'
            Options.Editing = False
            Width = 140
          end
          object colOCosteNormal: TcxGridColumn
            Caption = 'Coste/h norm'
            Options.Editing = False
            Width = 100
          end
          object colOCosteExtra: TcxGridColumn
            Caption = 'Coste/h extra'
            Options.Editing = False
            Width = 100
          end
          object colOGrupoHorario: TcxGridColumn
            Caption = 'Grupo horario'
            Options.Editing = False
            Width = 100
          end
          object colOEmail: TcxGridColumn
            Caption = 'Email'
            Options.Editing = False
            Width = 180
          end
          object colOLocalNombre: TcxGridColumn
            Caption = 'Local: Nombre'
            Options.Editing = False
            Width = 180
          end
          object colOAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 140
          end
        end
        object lvOperarios: TcxGridLevel
          GridView = tvOperarios
        end
      end
    end
    object tabCentroMaquina: TcxTabSheet
      Caption = 'Centros '#215' M'#225'quinas'
      object gridCentroMaquina: TcxGrid
        Left = 0
        Top = 0
        Width = 1272
        Height = 442
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvCentroMaquina: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsBehavior.IncSearch = True
          OptionsSelection.CellSelect = False
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvCentroMaquinaStylesGetContentStyle
          object colCMEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colCMCentro: TcxGridColumn
            Caption = 'Centro ERP'
            Options.Editing = False
            Width = 110
          end
          object colCMMaquina: TcxGridColumn
            Caption = 'M'#225'quina ERP'
            Options.Editing = False
            Width = 110
          end
          object colCMOrden: TcxGridColumn
            Caption = 'Orden'
            Options.Editing = False
            Width = 70
          end
          object colCMCoste: TcxGridColumn
            Caption = 'Coste/h'
            Options.Editing = False
            Width = 80
          end
          object colCMCorrPrep: TcxGridColumn
            Caption = '%Corr Prep'
            Options.Editing = False
            Width = 90
          end
          object colCMCorrFab: TcxGridColumn
            Caption = '%Corr Fab'
            Options.Editing = False
            Width = 90
          end
          object colCMError: TcxGridColumn
            Caption = 'Aviso'
            Options.Editing = False
            Width = 320
          end
          object colCMAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 140
          end
        end
        object lvCentroMaquina: TcxGridLevel
          GridView = tvCentroMaquina
        end
      end
    end
    object tabModelos: TcxTabSheet
      Caption = 'Modelos horarios'
      ImageIndex = -1
      PageIndex = 5
      object gridModelos: TcxGrid
        Left = 0
        Top = 0
        Width = 1280
        Height = 448
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvModelos: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          OptionsBehavior.IncSearch = True
          OptionsCustomize.ColumnFiltering = True
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvModelosStylesGetContentStyle
          object colHMEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colHMCodigo: TcxGridColumn
            Caption = 'C'#243'digo ERP'
            Options.Editing = False
            Width = 90
          end
          object colHMDescripcion: TcxGridColumn
            Caption = 'Descripci'#243'n'
            Options.Editing = False
            Width = 280
          end
          object colHMNumLineas: TcxGridColumn
            Caption = 'L'#237'neas'
            Options.Editing = False
            Width = 80
          end
          object colHMLocalNombre: TcxGridColumn
            Caption = 'Local: Nombre'
            Options.Editing = False
            Width = 220
          end
          object colHMAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 140
          end
        end
        object lvModelos: TcxGridLevel
          GridView = tvModelos
        end
      end
    end
    object tabAlmacenes: TcxTabSheet
      Caption = 'Almacenes'
      ImageIndex = -1
      PageIndex = 6
      object gridAlmacenes: TcxGrid
        Left = 0
        Top = 0
        Width = 1280
        Height = 448
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvAlmacenes: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          OptionsBehavior.IncSearch = True
          OptionsCustomize.ColumnFiltering = True
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvAlmacenesStylesGetContentStyle
          object colALEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colALCodigo: TcxGridColumn
            Caption = 'C'#243'digo ERP'
            Options.Editing = False
            Width = 90
          end
          object colALNombre: TcxGridColumn
            Caption = 'Nombre'
            Options.Editing = False
            Width = 220
          end
          object colALGrupo: TcxGridColumn
            Caption = 'Grupo'
            Options.Editing = False
            Width = 90
          end
          object colALResponsable: TcxGridColumn
            Caption = 'Responsable'
            Options.Editing = False
            Width = 140
          end
          object colALMunicipio: TcxGridColumn
            Caption = 'Municipio'
            Options.Editing = False
            Width = 130
          end
          object colALProvincia: TcxGridColumn
            Caption = 'Provincia'
            Options.Editing = False
            Width = 110
          end
          object colALLocalNombre: TcxGridColumn
            Caption = 'Local: Nombre'
            Options.Editing = False
            Width = 180
          end
          object colALAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 140
          end
        end
        object lvAlmacenes: TcxGridLevel
          GridView = tvAlmacenes
        end
      end
    end
    object tabFamilias: TcxTabSheet
      Caption = 'Familias'
      ImageIndex = -1
      PageIndex = 7
      object gridFamilias: TcxGrid
        Left = 0
        Top = 0
        Width = 1280
        Height = 448
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvFamilias: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          OptionsBehavior.IncSearch = True
          OptionsCustomize.ColumnFiltering = True
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvFamiliasStylesGetContentStyle
          object colFAEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colFAFamilia: TcxGridColumn
            Caption = 'Familia'
            Options.Editing = False
            Width = 90
          end
          object colFASubfamilia: TcxGridColumn
            Caption = 'Subfamilia'
            Options.Editing = False
            Width = 90
          end
          object colFADescripcion: TcxGridColumn
            Caption = 'Descripci'#243'n'
            Options.Editing = False
            Width = 260
          end
          object colFATipo: TcxGridColumn
            Caption = 'Tipo'
            Options.Editing = False
            Width = 70
          end
          object colFASeccion: TcxGridColumn
            Caption = 'Secci'#243'n'
            Options.Editing = False
            Width = 100
          end
          object colFADepartamento: TcxGridColumn
            Caption = 'Departamento'
            Options.Editing = False
            Width = 120
          end
          object colFALocalDesc: TcxGridColumn
            Caption = 'Local: Descripci'#243'n'
            Options.Editing = False
            Width = 200
          end
          object colFAAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 140
          end
        end
        object lvFamilias: TcxGridLevel
          GridView = tvFamilias
        end
      end
    end
    object tabCalendarios: TcxTabSheet
      Caption = 'Calendarios'
      ImageIndex = -1
      PageIndex = 8
      object gridCalendarios: TcxGrid
        Left = 0
        Top = 0
        Width = 1280
        Height = 448
        Align = alClient
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object tvCalendarios: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          OptionsBehavior.IncSearch = True
          OptionsCustomize.ColumnFiltering = True
          OptionsSelection.MultiSelect = True
          OptionsSelection.CheckBoxVisibility = [cbvDataRow, cbvColumnHeader]
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsSelection.UnselectFocusedRecordOnExit = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          Styles.OnGetContentStyle = tvCalendariosStylesGetContentStyle
          object colCAEstado: TcxGridColumn
            Caption = 'Estado'
            Options.Editing = False
            Width = 110
          end
          object colCAGrupo: TcxGridColumn
            Caption = 'Grupo horario ERP'
            Options.Editing = False
            Width = 140
          end
          object colCALocalNombre: TcxGridColumn
            Caption = 'Local: Nombre'
            Options.Editing = False
            Width = 180
          end
          object colCADiasTotales: TcxGridColumn
            Caption = 'D'#237'as'
            Options.Editing = False
            Width = 70
          end
          object colCADiasLab: TcxGridColumn
            Caption = 'D'#237'as laborables'
            Options.Editing = False
            Width = 120
          end
          object colCADiasFest: TcxGridColumn
            Caption = 'D'#237'as festivos'
            Options.Editing = False
            Width = 110
          end
          object colCAAccion: TcxGridColumn
            Caption = 'Si conflicto'
            PropertiesClassName = 'TcxComboBoxProperties'
            Width = 140
          end
        end
        object lvCalendarios: TcxGridLevel
          GridView = tvCalendarios
        end
      end
    end
  end
end
