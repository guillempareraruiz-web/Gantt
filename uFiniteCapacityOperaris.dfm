object frmFiniteCapacityOperaris: TfrmFiniteCapacityOperaris
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Planificaci'#243'n por operario'
  ClientHeight = 739
  ClientWidth = 1336
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
  PixelsPerInch = 96
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 70
    Width = 1336
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    ExplicitTop = 0
    ExplicitWidth = 1320
    object lblTitle: TLabel
      Left = 16
      Top = 18
      Width = 255
      Height = 21
      Caption = 'Planificaci'#243'n de carga por operario'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object cbRango: TComboBox
      Left = 320
      Top = 18
      Width = 160
      Height = 25
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbRangoChange
    end
    object cbOrden: TComboBox
      Left = 496
      Top = 18
      Width = 200
      Height = 25
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbOrdenChange
    end
    object cbFiltroOp: TComboBox
      Left = 712
      Top = 18
      Width = 200
      Height = 25
      Style = csDropDownList
      TabOrder = 2
      OnChange = cbFiltroOpChange
    end
    object chkSoloCapacitados: TCheckBox
      Left = 928
      Top = 22
      Width = 130
      Height = 17
      Caption = 'Solo capacitados'
      TabOrder = 3
      OnClick = chkSoloCapacitadosClick
    end
    object btnOperariosVisibles: TButton
      Left = 1080
      Top = 18
      Width = 160
      Height = 25
      Caption = 'Operarios visibles...'
      TabOrder = 4
      OnClick = btnOperariosVisiblesClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 695
    Width = 1336
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 1
    ExplicitTop = 656
    ExplicitWidth = 1320
    object lblResumen: TLabel
      Left = 16
      Top = 14
      Width = 53
      Height = 17
      Caption = 'Resumen'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnOK: TButton
      Left = 1144
      Top = 8
      Width = 80
      Height = 28
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 1232
      Top = 8
      Width = 80
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 126
    Width = 1336
    Height = 569
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 2
    ExplicitTop = 56
    ExplicitWidth = 1320
    ExplicitHeight = 600
    object splPanels: TSplitter
      Left = 280
      Top = 0
      Width = 6
      Height = 569
      Color = 14737632
      ParentColor = False
      ExplicitHeight = 600
    end
    object pnlPendientes: TPanel
      Left = 0
      Top = 0
      Width = 280
      Height = 569
      Align = alLeft
      BevelOuter = bvNone
      Color = 16579836
      ParentBackground = False
      TabOrder = 0
      ExplicitHeight = 600
      object pnlPendientesHeader: TPanel
        Left = 0
        Top = 0
        Width = 280
        Height = 64
        Align = alTop
        BevelOuter = bvNone
        Color = 16579836
        ParentBackground = False
        TabOrder = 0
        object lblPendientes: TLabel
          Left = 8
          Top = 6
          Width = 92
          Height = 17
          Caption = 'OTs pendientes'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 6316128
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object edFiltroArticulo: TEdit
          Left = 8
          Top = 30
          Width = 264
          Height = 25
          TabOrder = 0
          TextHint = 'Filtrar por art'#237'culo / OT...'
          OnChange = edFiltroArticuloChange
        end
      end
    end
    object pnlOperarios: TPanel
      Left = 286
      Top = 0
      Width = 1050
      Height = 569
      Align = alClient
      BevelOuter = bvNone
      Color = 16053492
      ParentBackground = False
      TabOrder = 1
      ExplicitWidth = 1034
      ExplicitHeight = 600
    end
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1336
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 3
    ExplicitTop = -27
    ExplicitWidth = 1320
    DesignSize = (
      1336
      70)
    object Label1: TLabel
      Left = 68
      Top = 6
      Width = 207
      Height = 32
      Caption = 'Carga por operario'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 68
      Top = 40
      Width = 227
      Height = 15
      Caption = 'Planificaci'#243'n de recursos humanos a tareas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object Label28: TLabel
      Left = 1230
      Top = 40
      Width = 67
      Height = 19
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'Opciones'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object cxButton9: TcxButton
      Left = 1302
      Top = 42
      Width = 18
      Height = 18
      Cursor = crHandPoint
      Anchors = [akTop, akRight]
      Kind = cxbkDropDown
      LookAndFeel.NativeStyle = False
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.SourceHeight = 16
      OptionsImage.Glyph.SourceWidth = 16
      OptionsImage.Glyph.Data = {
        3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
        462D38223F3E0D0A3C7376672076657273696F6E3D22312E31222069643D224C
        617965725F312220786D6C6E733D22687474703A2F2F7777772E77332E6F7267
        2F323030302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F77
        77772E77332E6F72672F313939392F786C696E6B2220783D223070782220793D
        22307078222076696577426F783D2230203020333220333222207374796C653D
        22656E61626C652D6261636B67726F756E643A6E657720302030203332203332
        3B2220786D6C3A73706163653D227072657365727665223E262331333B262331
        303B3C7374796C6520747970653D22746578742F6373732220786D6C3A737061
        63653D227072657365727665223E2E59656C6C6F777B66696C6C3A2346464231
        31353B7D262331333B262331303B2623393B2E5265647B66696C6C3A23443131
        4331433B7D262331333B262331303B2623393B2E426C75657B66696C6C3A2331
        31373744373B7D262331333B262331303B2623393B2E477265656E7B66696C6C
        3A233033394332333B7D262331333B262331303B2623393B2E426C61636B7B66
        696C6C3A233732373237323B7D262331333B262331303B2623393B2E57686974
        657B66696C6C3A234646464646463B7D262331333B262331303B2623393B2E73
        74307B6F7061636974793A302E353B7D262331333B262331303B2623393B2E73
        74317B646973706C61793A6E6F6E653B7D262331333B262331303B2623393B2E
        7374327B646973706C61793A696E6C696E653B66696C6C3A233033394332333B
        7D262331333B262331303B2623393B2E7374337B646973706C61793A696E6C69
        6E653B66696C6C3A234431314331433B7D262331333B262331303B2623393B2E
        7374347B646973706C61793A696E6C696E653B66696C6C3A233732373237323B
        7D3C2F7374796C653E0D0A3C672069643D22416C69676E4A757374696679223E
        0D0A09093C7061746820636C6173733D22426C61636B2220643D224D32382C38
        4834563668323456387A204D32382C3130483476326832345631307A204D3238
        2C3134483476326832345631347A204D32382C3232483476326832345632327A
        204D32382C3138483476326832345631387A222F3E0D0A093C2F673E0D0A3C2F
        7376673E0D0A}
      PaintStyle = bpsGlyph
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      SpeedButtonOptions.Transparent = True
      TabOrder = 0
    end
    object imgSection: TcxImage
      AlignWithMargins = True
      Left = 3
      Top = 6
      Margins.Top = 6
      Margins.Right = 5
      Margins.Bottom = 12
      Align = alLeft
      Picture.Data = {
        0D546478536D617274496D6167653C3F786D6C2076657273696F6E3D22312E30
        2220656E636F64696E673D225554462D38223F3E0D0A3C737667207669657742
        6F783D223020302032342032342220786D6C6E733D22687474703A2F2F777777
        2E77332E6F72672F323030302F737667223E0D0A093C706174682066696C6C3D
        2223464646464646222066696C6C2D6F7061636974793D22302E352220643D22
        4D31322031314331342E373631342031312031372031332E3233383620313720
        31365632324831355631364331352031342E343032332031332E373531312031
        332E303936332031322E313736332031332E303035314C31322031334331302E
        3430323320313320392E30393633342031342E3234383920392E303035303920
        31352E383233374C39203136563232483756313643372031332E323338362039
        2E32333835382031312031322031315A4D352E3520313443352E373738383520
        313420362E30353030392031342E3033323620362E333130312031342E303934
        3243362E31343230322031342E35393420362E30333837332031352E31323220
        362E30303839362031352E363639334C362031364C362E303030372031362E30
        38353643352E38383735372031362E3034353620352E37363832312031362E30
        31383720352E36343434362031362E303036394C352E3520313643342E373230
        3320313620342E30373935352031362E3539343920342E30303638372031372E
        333535354C342031372E3556323248325631372E3543322031352E3536372033
        2E35363720313420352E352031345A4D31382E352031344332302E3433332031
        342032322031352E3536372032322031372E355632324832305631372E354332
        302031362E373230332031392E343035312031362E303739362031382E363434
        352031362E303036394C31382E352031364331382E333234382031362031382E
        313536362031362E30332031382E303030332031362E303835324C3138203136
        4331382031352E333334332031372E383931362031342E3639342031372E3639
        31352031342E303935364331372E393439392031342E303332362031382E3232
        31312031342031382E352031345A4D352E35203843362E383830373120382038
        20392E313139323920382031302E3543382031312E3838303720362E38383037
        3120313320352E3520313343342E313139323920313320332031312E38383037
        20332031302E35433320392E313139323920342E3131393239203820352E3520
        385A4D31382E3520384331392E38383037203820323120392E31313932392032
        312031302E354332312031312E383830372031392E383830372031332031382E
        352031334331372E313139332031332031362031312E38383037203136203130
        2E3543313620392E31313932392031372E3131393320382031382E3520385A4D
        352E3520313043352E323233383620313020352031302E323233392035203130
        2E3543352031302E3737363120352E323233383620313120352E352031314335
        2E373736313420313120362031302E3737363120362031302E3543362031302E
        3232333920352E373736313420313020352E352031305A4D31382E3520313043
        31382E323233392031302031382031302E323233392031382031302E35433138
        2031302E373736312031382E323233392031312031382E352031314331382E37
        3736312031312031392031302E373736312031392031302E354331392031302E
        323233392031382E373736312031302031382E352031305A4D31322032433134
        2E32303931203220313620332E3739303836203136203643313620382E323039
        31342031342E3230393120313020313220313043392E37393038362031302038
        20382E323039313420382036433820332E373930383620392E37393038362032
        20313220325A4D313220344331302E38393534203420313020342E3839353433
        203130203643313020372E31303435372031302E383935342038203132203843
        31332E31303436203820313420372E3130343537203134203643313420342E38
        393534332031332E31303436203420313220345A222F3E0D0A3C2F7376673E0D
        0A}
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Properties.ShowFocusRect = False
      Style.BorderStyle = ebsNone
      TabOrder = 1
      Transparent = True
      Height = 52
      Width = 56
    end
  end
  object pmCard: TPopupMenu
    Left = 600
    Top = 200
    object miLock: TMenuItem
      Caption = 'Bloquear / desbloquear asignaci'#243'n'
      OnClick = miLockClick
    end
    object miUnassign: TMenuItem
      Caption = 'Quitar asignaci'#243'n'
      OnClick = miUnassignClick
    end
  end
  object pmOperario: TPopupMenu
    Left = 700
    Top = 200
    object miDesasignarTodo: TMenuItem
      Caption = 'Desasignar todo del operario'
      OnClick = miDesasignarTodoClick
    end
    object miOpSep1: TMenuItem
      Caption = '-'
    end
    object miBloquearTodo: TMenuItem
      Caption = 'Bloquear todas las asignaciones'
      OnClick = miBloquearTodoClick
    end
    object miDesbloquearTodo: TMenuItem
      Caption = 'Desbloquear todas las asignaciones'
      OnClick = miDesbloquearTodoClick
    end
    object miOpSep2: TMenuItem
      Caption = '-'
    end
    object miGestionAusencias: TMenuItem
      Caption = 'Gestionar ausencias del operario...'
      OnClick = miGestionAusenciasClick
    end
    object miGestionCalendario: TMenuItem
      Caption = 'Gestionar calendario del operario...'
      OnClick = miGestionCalendarioClick
    end
  end
  object pmAbsence: TPopupMenu
    Left = 800
    Top = 200
    object miQuitarAusencia: TMenuItem
      Caption = 'Quitar ausencia'
      OnClick = miQuitarAusenciaClick
    end
  end
end
