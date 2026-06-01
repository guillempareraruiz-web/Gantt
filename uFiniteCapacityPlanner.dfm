object frmFiniteCapacityPlanner: TfrmFiniteCapacityPlanner
  Left = 0
  Top = 0
  BorderStyle = bsNone
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
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 17
  object splitter: TSplitter
    Left = 320
    Top = 71
    Width = 5
    Height = 629
    Color = 14737632
    ParentColor = False
    ExplicitTop = 51
    ExplicitHeight = 621
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1300
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 68
      Top = 4
      Width = 400
      Height = 36
      AutoSize = False
      Caption = 'Carga por centro'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object LblRango: TLabel
      Left = 325
      Top = 7
      Width = 148
      Height = 19
      AutoSize = False
      Caption = 'Fecha                         Rango'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object lblSubtitle: TLabel
      Left = 68
      Top = 40
      Width = 219
      Height = 15
      Caption = 'Planificaci'#243'n de tareas por Centro Trabajo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object FDtpStart: TDateTimePicker
      Left = 324
      Top = 28
      Width = 100
      Height = 23
      Date = 46167.000000000000000000
      Time = 0.843935393517313100
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnChange = OnStartDateChange
    end
    object FCmbRange: TComboBox
      Left = 430
      Top = 28
      Width = 110
      Height = 23
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 4
      ParentFont = False
      TabOrder = 1
      Text = '1 semana'
      OnChange = OnRangeChange
      Items.Strings = (
        '1 d'#237'a'
        '2 d'#237'as'
        '3 d'#237'as'
        '5 d'#237'as'
        '1 semana'
        '2 semanas'
        '1 mes')
    end
    object pnlKpiPend: TPanel
      Left = 838
      Top = 10
      Width = 110
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 3
      object lblKpiPendVal: TLabel
        Left = 0
        Top = 4
        Width = 110
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiPendCap: TLabel
        Left = 0
        Top = 28
        Width = 110
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Pendientes'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiAsig: TPanel
      Left = 954
      Top = 10
      Width = 110
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 4
      object lblKpiAsigVal: TLabel
        Left = 0
        Top = 4
        Width = 110
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiAsigCap: TLabel
        Left = 0
        Top = 28
        Width = 110
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Asignadas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiTotal: TPanel
      Left = 1070
      Top = 10
      Width = 110
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 5
      object lblKpiTotalVal: TLabel
        Left = 0
        Top = 4
        Width = 110
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiTotalCap: TLabel
        Left = 0
        Top = 28
        Width = 110
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Total OTs'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlKpiCap: TPanel
      Left = 1186
      Top = 10
      Width = 110
      Height = 50
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 5526612
      ParentBackground = False
      TabOrder = 6
      object lblKpiCapVal: TLabel
        Left = 0
        Top = 4
        Width = 110
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Caption = '0%'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -18
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblKpiCapCap: TLabel
        Left = 0
        Top = 28
        Width = 110
        Height = 16
        Alignment = taCenter
        AutoSize = False
        Caption = 'Capacidad'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14869218
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
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
        4D3320313956352E3730303436433320352E323739393520332E323633303720
        342E393034333720332E363538323620342E37363036374C31332E3332393120
        312E32343339384331332E3538383620312E31343936312031332E3837353520
        312E32383334392031332E3936393920312E35343330314331332E3938393820
        312E353937373820313420312E363535363120313420312E373133383856362E
        363636374C32302E3331363220382E37373231314332302E3732343620382E39
        3038323220323120392E323930333620323120392E3732303739563139483233
        563231483156313948335A4D3520313948313256332E38353534334C3520362E
        34303038395631395A4D31392031395631302E343431364C313420382E373734
        38385631394831395A222F3E0D0A3C2F7376673E0D0A}
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Properties.ShowFocusRect = False
      Style.BorderStyle = ebsNone
      TabOrder = 2
      Transparent = True
      Height = 52
      Width = 56
    end
  end
  object pnlSeparator: TPanel
    Left = 0
    Top = 70
    Width = 1300
    Height = 1
    Align = alTop
    BevelOuter = bvNone
    Color = 14737632
    TabOrder = 1
  end
  object pnlPending: TPanel
    Left = 0
    Top = 71
    Width = 320
    Height = 629
    Align = alLeft
    BevelOuter = bvNone
    Color = 15263458
    TabOrder = 2
    DesignSize = (
      320
      629)
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
    object FBtnOptions: TPanel
      Left = 280
      Top = 4
      Width = 32
      Height = 28
      Cursor = crHandPoint
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Color = 15263458
      ParentBackground = False
      TabOrder = 1
      OnClick = OnBtnOptionsClick
      object LblDots: TLabel
        Left = 0
        Top = 0
        Width = 32
        Height = 28
        Cursor = crHandPoint
        Align = alClient
        Alignment = taCenter
        AutoSize = False
        Caption = '...'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 8947848
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        OnClick = OnBtnOptionsClick
      end
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
    Top = 71
    Width = 975
    Height = 629
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    TabOrder = 3
    ExplicitLeft = 326
    ExplicitTop = 76
    object pnlHeaderCentres: TPanel
      Left = 0
      Top = 0
      Width = 975
      Height = 72
      Align = alTop
      BevelOuter = bvNone
      Color = 15789544
      ParentBackground = False
      TabOrder = 0
      DesignSize = (
        975
        72)
      object lblCentresTitle: TLabel
        Left = 0
        Top = 0
        Width = 164
        Height = 72
        Align = alLeft
        AutoSize = False
        Caption = '   CENTROS DE TRABAJO'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -14
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        ExplicitHeight = 36
      end
      object lblFilterCaption: TLabel
        Left = 736
        Top = 1
        Width = 60
        Height = 36
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'Centros:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object lblLayout: TLabel
        Left = 401
        Top = 9
        Width = 56
        Height = 19
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'Layout:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object Label1: TLabel
        Left = 320
        Top = 9
        Width = 72
        Height = 19
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'Undo/Redo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object cbCentros: TcxCheckComboBox
        Left = 736
        Top = 28
        Anchors = [akTop, akRight]
        AutoSize = False
        ParentFont = False
        Properties.EmptySelectionText = 'Todos los centros'
        Properties.Items = <>
        Properties.OnEditValueChanged = cbCentrosChange
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -10
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 0
        Height = 24
        Width = 230
      end
      object cmbLayout: TcxComboBox
        Left = 401
        Top = 28
        Anchors = [akTop, akRight]
        AutoSize = False
        ParentFont = False
        Properties.DropDownListStyle = lsFixedList
        Properties.OnChange = cmbLayoutChange
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 1
        Height = 24
        Width = 220
      end
      object btnLayoutNew: TcxButton
        Left = 627
        Top = 27
        Width = 28
        Height = 25
        Anchors = [akTop, akRight]
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 16
        OptionsImage.Glyph.SourceWidth = 16
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000002A744558745469746C65004865616465723B4164642047726F757020
          4865616465723B4865616465723B47726F7570C7BAD3710000020E4944415478
          5E6D904B4855511486BF7DBD1605358BA0913409891E8330ACE8711B54143510
          036BD44012A14142761B5793A041051909054184103D90F262758D027B586820
          040DEC0181482074D5D473CEFA83DD3E878BF9C3E25F6CF6DEEB5BBF0372DD3D
          C32F5CCEED064020EF42A43D34ED5BC7A337E7F8363E8C120670564078D55CBE
          F55EA92C2DCB2A53F1E6767D9EE856E78D6D1A183BCD99EB8DE40192444870A9
          F41D2F11244EEC58C3FD7207633F3F221C5F27DF12CD273CEE1D14A6721E7049
          920020339043291B62F9921ABEFC18A2ADA595D1F12754E626D8BA6B15896206
          FB7F15FE11980051998A90EF0DC96118BF6722EA563770E576171234EC5DC6BB
          67332090540A048604C5436BC10991CA91CF394E355F25E71CAD1737333D3F49
          1CD7B2B130EB469ED7A61918027A9E8E2284094F6226847CDFBCBF9EFABA4686
          FA5E638AFB3FF4E501514D40D381F5380108E1BCE31DF2358E8EE35D4C4DCFB3
          72C5D2239200AA0824EEF57E422624300914680495A93F9C3DB993F3D75E512D
          4F606185A30737E000044A01704802877733236055130819DC7D38924D94E41D
          2910CC506CDFEDEF2EFCC0C56618A2E5F026C065D3B30C0281492466FFAD8085
          10EF3C18091385009977907C06C5F63D248BAD60264CA2EDD816C2FD4CAAA230
          095B84C0A2B9D972E78552217B983655410626A268F6251013E442D5A679B040
          0BCE141E47920CE02FD20E7A0B1EB5A8120000000049454E44AE426082}
        TabOrder = 2
        OnClick = btnLayoutNewClick
      end
      object btnLayoutDelete: TcxButton
        Left = 655
        Top = 27
        Width = 28
        Height = 25
        Anchors = [akTop, akRight]
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 16
        OptionsImage.Glyph.SourceWidth = 16
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C00000014744558745469746C650052656D6F76653B466F6F7465
          723B0C8041730000007549444154785EED90310A80300C457B386F2278044F90
          23081EC10B7417AF200EA5938BB363C748842221B6A428B81878D00EFFF11383
          8827008025C41C1328272FE8EC9285E68B067F8371DE84A4B8C13E59747515BF
          F4261A2168875E7005245AC1AD8472AF0B12285748C08E18566F0876C4271CB0
          B22928B6CD9EFE0000000049454E44AE426082}
        TabOrder = 3
        OnClick = btnLayoutDeleteClick
      end
      object btnLayoutSave: TcxButton
        Left = 683
        Top = 27
        Width = 28
        Height = 25
        Anchors = [akTop, akRight]
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 16
        OptionsImage.Glyph.SourceWidth = 16
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000000B744558745469746C6500536176653BF9E8F9090000004849444154
          785EDDD0C10900200885E1D66C1BAFCDD2146FB15E10782A4A940E25FC1E3FC4
          4432D45825577A9A00E39C0100CB747EBD200ED8BB0C3472971950F021401C4F
          140542756780187A6CE7455E0000000049454E44AE426082}
        TabOrder = 4
        OnClick = btnLayoutSaveClick
      end
      object btnUndo: TcxButton
        Left = 320
        Top = 27
        Width = 28
        Height = 25
        Anchors = [akTop, akRight]
        Enabled = False
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 16
        OptionsImage.Glyph.SourceWidth = 16
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C00000016744558745469746C6500556E646F3B4172726F773B45
          6469743BCB5CF1270000008C49444154785ECDD3B109C520148561E77870C910
          A904E7B17602E16D94CED23152A677899B539C40C8BD8DA449F11150F3838A41
          555FF95020A5542190408106831AC7846B4C401989B0817A3817DD00EDFC76C8
          B050867E8B881BA00356E03C00C7AE48318187CAC03392196836605527B03030
          E6AFF17DC06E61F6E79F7788B391BFBDC6F988C0471ED309618474668A10A3F8
          0000000049454E44AE426082}
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 5
        OnClick = OnUndoClick
      end
      object btnRedo: TcxButton
        Left = 353
        Top = 27
        Width = 28
        Height = 25
        Anchors = [akTop, akRight]
        Enabled = False
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 16
        OptionsImage.Glyph.SourceWidth = 16
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C00000016744558745469746C65005265646F3B4172726F773B45
          6469743BE851AFAC0000008F49444154785ED5D3BD0DC320108661CF11E9C410
          AE2C310FB52740F246EE283D464AF75EE2F2155FA41306234493144FE38357F8
          6F52D5213F12F0DE7F09AC90E0A2C46B62D6C55260811DB462E79A089A07C46C
          3E2080A30007676FD05260359B670EEDE96638416B81C441E0200F44D0A7C0C5
          81BB05B8B933D0D6BC85B6FA437CF506EC6BDC46BE44F9CF9FE90316AE74665C
          F622310000000049454E44AE426082}
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 6
        OnClick = OnRedoClick
      end
    end
  end
end
