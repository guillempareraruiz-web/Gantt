object frmVistaProyectos: TfrmVistaProyectos
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'M'#243'dulo de Proyectos'
  ClientHeight = 640
  ClientWidth = 1180
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object splMain: TSplitter
    Left = 560
    Top = 70
    Width = 6
    Height = 570
    ExplicitTop = 44
    ExplicitHeight = 596
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1180
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 6313290
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 24
      Top = 10
      Width = 231
      Height = 32
      Caption = 'M'#243'dulo de Proyectos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 24
      Top = 44
      Width = 208
      Height = 15
      Caption = 'Planificaci'#243'n por tareas y dependencias'
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
    Top = 70
    Width = 560
    Height = 570
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object pnlCabeceraWbs: TPanel
      Left = 0
      Top = 0
      Width = 560
      Height = 24
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      DesignSize = (
        560
        24)
      object lblCabeceraWbs: TLabel
        Left = 8
        Top = 4
        Width = 106
        Height = 13
        Caption = 'Listado de proyectos'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object btnConfigProyectos: TcxButton
        Left = 534
        Top = 2
        Width = 20
        Height = 19
        Hint = 'Filtrar por la entidad del modo activo'
        Anchors = [akTop, akRight]
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'DevExpressStyle'
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 12
        OptionsImage.Glyph.SourceWidth = 12
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
          F40000002B744558745469746C650053657475703B437573746F6D697A3B4465
          7369676E3B53657474696E673B50726F70657274381FB5210000096F49444154
          785EA5567B7054D51DFEF6EEDD6437316C1E04121342480884902AA09006E411
          218040159929C1542538C5E2D48E222A3830016CA538B60E582B152818A98101
          81F20A0F85407824BC04250592051260CD83D78624FBBC7BEFE9EF9CB9F74EA4
          FEC3F4DC7C39B37BCF39DFF77B9EB5E0E107DF2311ACFACC0723A8044DE02186
          4CC0B2951B7F9E8A897F62620C5834B75890BF5DFAC9134E67FC49064D506B60
          38537D227FF7D6CFCF0060A51FAE674CDF241E4DCC80F88A0980B0BC740E6483
          EB9DDF4F47D76193ADA67794B0CA00980222ED8EA251F98FE1974FE6808FEAD3
          B5A83D77AE08C07982F6FEFC590F7A4C707BEE7B3933480F96AFF8D2F4C0CF11
          770523314280EE729B64952666A43F0A5F2084901246AF941E9024790280D207
          C220E9E0438D7346AB77DA3A356EBDA6AAE60252A4FD847CC2AF5E702CF9E88B
          1D848AB90B3FCE0310C1895F9AFD4E9F05EF7FB6D01913939398E014E4E1B08A
          F83827121262073CF3FCEC85538B6667027070CCFCDD82516F2D5AB967EEC215
          DB33FBFDC20940EE1EFB8844FC5035CDF4008F91E9AEF144FE54C1C42DD3268F
          7EC66A9570F8F8F9C2451FACA9D0342DE08C753E37B07F6FEB90C7FA41515441
          AED1DE0E5F10AFBFF6228E1D3F33FFD63DEFDBE91903F6C22245A7A525178CCE
          1F2C84026CE3F64D6B8A1BAF5EBC9F181FA3BCB1E06366C667E95F3760F1BC97
          447C4B3FFCE78EA2A9E32667928B29F6B04A125CD76EC21F0822373B03926441
          20A420180C435135903088C4E26E9265F2A284CBF50D88723890999182F6CE00
          3CED9DB879C38D55ABCAF6EFFDF79A6900026327CDD20E56AC373CA0991E601A
          544D15D69172158C518C53932088152225A81AE3C43A20669510082A604C4352
          721209B7E0C7560FDADABCB0CA568443E24CD9C82D23074C0164AD48B67BF76E
          FFB1F2F8B9299464123F8CB8A02AC24A681C1A9F0D722688359521CC4B8D0B21
          F1C150185A98CEE486682ABAD9EDD8B7BF129EBB2D7FD1FB05E3FBCD24A40F66
          D1FFFDA30517DC3FB6EEAF27B74B168B10C785A826299118507936EB228888C8
          851035ACF2F0086FC964FDA53A175CAE2B87CF54579CE6744280FA8000C6600E
          728FDFEB0DC06295B8952654DD620B3DF6081BA2A32228D69170D8236021B161
          DD03E44C3E0B0100280C1DF459F3A1CB387AA8DCD2B549587448334ADEEC3B60
          E0A0DAB75E2BB20695B070A7E97A5513165D715DC3CE3DDFA2A1C12D3CD7273D
          0DE3278EA67E404947C27988949082905E2571B1D128FF6ABB76AAE6705E4D55
          C5450021C313B241AC43EED133F5D5DCFEE9569E7441452162E83167827CCFDE
          8328DFB8A32518F096DE6FBB7D02D02C2D2D4D23CE5FB8B8E4D7D32627E5E50F
          4587D7FF13E1814008997D33A4A61F9B7E0B542C06E0D745289CDC5A32675176
          4CB7D822ABCD3AD919D36DC8AB339F85DDEE809736323DD9C8C7686C68C49FFE
          FCE9D5862B3F4CB856FF5D3380B06E80DC276B504AFF8143F7CC9BFB6A5F5B64
          14BC7EDA2B046862AF4D62D8B9F3003C1ECF45BFDFBBF7EEADE6CDC72AB75F90
          B980F884C4DA31239F4076563AB931112145430777A56A261D1C9111F87ADB3E
          B2C6B74C270F11545D80DAE03ADF94969EBD7CDF81236B8B5F98C6F71B9E1350
          25A0B8F879A84A28E772DDD59CCAC335F300C40BD77382C231C3D03D210E9E0E
          3FDA3A7CBC668998438351322DAD77D0DA74F5A06EB97AC7D3C16EDD6D377ABF
          D2E0FAFE506BCB5D748B8982A69727CD424828A4C2DD720FB7DA7CC8C919208C
          13DD1F8028213EFCA110C28AF6BF754EE0F52CCB369EED66E2D23BD6B57A2C54
          B75659862C5921F631BD3768106731A6193CC238B10500F3797DD8BDBF0A77EE
          DC4364A40CA613AB2A8193AB4C78A457AF646464E51670E504A96782534AEAEE
          34123822F7F1E1637BF74EA5F5BAE754CDEC9A9285213E36069A12C4C993670D
          AF2A7CA3EABEDE30E85FE53B96BFFFC1A7B5A54B57A2B3A35364BF10111642D0
          E90BA2B07014121293DF23A21400764EAAC3913B68784A8FA494F9630BF22984
          5EA36F88D9221A9A8AB5ABCBB066F5FABABDBB767F5277F1EC53008232006DFF
          AEF5FF01B094B06CECA499CB8E54D5BC3E69CA388A9B02D30B84C4C4048C1F37
          322BC21651959533B8D47DDD55CD0392DABBDF88EEDD9397148CC9EBC9D7B81A
          9B0431D3C36777D871EEF40F68725F5F577D641B2F432F21405064A321F05980
          85D6D65DBDF9DA54D96ABDAF931B22DAA92CFB6665E0D147937AD6D6D67DDE9C
          D55F58979CD4034306E720B17B3CDCCDF7E0236F99770663B05A80EFBFFF416B
          6D6E580FE0BE4EAE129848A892398BF1C53F968A9E40701495BCBBA178FA94E7
          7AF74983970EA3FB9CA0F264156E95258932DD012765BBCD26537E90B84E1F6E
          DD6913A112AD5D086088B4D9E072D563F78E9DDF9CACDAFE328036429000A313
          1A19D9F52E887144D9451279FD01A396CD4C0E8455F86E07D174CB6310752135
          D6894486A286E17038F859D15D5A3F060D9BC4CE9FAA80A4131ADCD2F82933F3
          D27BF77A3ABB7F26FFCDA7136B309B9229A6CB4DA89A254BD0D7E9DF05430A52
          7BA5212535757846BF27F300C8A2F7A861F336148B8D3B21C619F76EE1D8E1E8
          E8F4F39E2EDE49562BFFBD088DE9F96008613AB1984DCBC55A2BC168E33E9F1F
          43F386213A26EE4D5D80E5C2D9031643801902434C381C86A7DD2B7E8E455128
          DCD76FE2D2A53AD8236D888C906101D3EF7FD33B206A44D27B4704C5BCBE1ECD
          EE1B745D3B204912172A42A1D200C074981E1007E82FD49AA3BB8BD7AEDBF4ED
          8DC61B686E6AC1BAB51BB0A16C63D5D6CDDBF7AF5BFB955673E21482812037C2
          0C09204109F871BCEA1856AF5AADEDD8BAEDE0A60DE527CABFDC8016B71B376F
          5CC7D6F28D55D7EA4FCFD2EF10D62F77B42902CFCF7803379AEEC2E8680989A9
          89A30B5FDC37725C71E5E343C74F0490C0919D9B3F7854E18C15D35F7E9B5554
          9E63655B0FB3F55F57B22D7BABD984675F61B4F66FC9A9FD799C9308C9E99983
          A7E60C7ABA2AFBB13107ED8E983400D17AA559FA0D1C09733C3BFD0F6874DF46
          C3CDDBA6084294D860763CF3BBA4B1934AEA2B0E9D6265DB0EB33212F059D92E
          F6E4F0E75C0052093104BB8E4708B10427C16190D79C77C11060E680281F7AAE
          5C6F15371B21A0234450748408BE50D07FF0F2251762BB45C36E8F10310FF87D
          87BA74B8A00E3FA19343FFAC9DF8CEC573D31CB29103252573C1F8A3328C2898
          2112C5B8EAF85C7D64B345EF96A1F676CF96DDBB0ECC61BB0E883DFCCFD7E9D9
          D2A5C36164E16FD8D16FBE32A9C8627158C94BAFE0FF1946B78C22C4117A107A
          12E209D146893D0CC17F0161B32CB90E1B30110000000049454E44AE426082}
        OptionsImage.Layout = blGlyphBottom
        ParentShowHint = False
        ShowHint = True
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 0
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnConfigProyectosClick
      end
      object btnTreeWide: TcxButton
        Left = 510
        Top = 2
        Width = 20
        Height = 19
        Hint = 'Filtrar por la entidad del modo activo'
        Anchors = [akTop, akRight]
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'DevExpressStyle'
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 12
        OptionsImage.Glyph.SourceWidth = 12
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C0000003C744558745469746C6500537472657463683B5472616E
          73666F726D3B4C617267653B456E6C617267653B4269673B457870616E643B45
          7874656E643B47726F7751876B1F0000005849444154785EDDD2C10940210C03
          D02EE852D2A15CE18FF05770894ABD040A5A301751C845C9A3A8A2AAC6640287
          EB56E0FBBB95DA22E07B7EB601505E02402280720A000180720204849C80BF03
          FE159EFA894CC48CCB00610B63B6764665380000000049454E44AE426082}
        OptionsImage.Layout = blGlyphBottom
        ParentShowHint = False
        ShowHint = True
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 1
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnTreeWideClick
      end
    end
    object tlWbs: TcxTreeList
      Left = 0
      Top = 24
      Width = 560
      Height = 546
      Align = alClient
      Bands = <
        item
        end>
      LookAndFeel.NativeStyle = False
      LookAndFeel.ScrollbarMode = sbmClassic
      LookAndFeel.SkinName = 'Office2019Colorful'
      Navigator.Buttons.CustomButtons = <>
      OptionsBehavior.CellHints = True
      OptionsData.Editing = False
      OptionsSelection.CellSelect = False
      ScrollbarAnnotations.CustomAnnotations = <>
      TabOrder = 0
      object colNombre: TcxTreeListColumn
        Caption.Text = 'Nombre'
        MinWidth = 220
        Options.Editing = False
        Width = 300
        Position.ColIndex = 0
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colDuracion: TcxTreeListColumn
        Caption.Text = 'Duraci'#243'n'
        MinWidth = 70
        Options.Editing = False
        Width = 80
        Position.ColIndex = 1
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colInicio: TcxTreeListColumn
        Caption.Text = 'Inicio'
        MinWidth = 85
        Options.Editing = False
        Width = 90
        Position.ColIndex = 2
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colFin: TcxTreeListColumn
        Caption.Text = 'Fin'
        MinWidth = 85
        Options.Editing = False
        Width = 90
        Position.ColIndex = 3
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colHolgura: TcxTreeListColumn
        Caption.Text = 'Holgura'
        MinWidth = 70
        Options.Editing = False
        Width = 80
        Position.ColIndex = 4
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colAvance: TcxTreeListColumn
        Caption.AlignHorz = taRightJustify
        Caption.Text = 'Avance'
        MinWidth = 60
        Options.Editing = False
        Width = 70
        Position.ColIndex = 5
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
    end
  end
  object pnlRight: TPanel
    Left = 566
    Top = 70
    Width = 614
    Height = 570
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
  end
end
