object frmDashboard: TfrmDashboard
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Dashboard'
  ClientHeight = 784
  ClientWidth = 1003
  Color = 15395562
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 1003
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 900
    DesignSize = (
      1003
      70)
    object lblTitulo: TLabel
      Left = 70
      Top = 5
      Width = 177
      Height = 32
      Caption = 'Panel de control'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 70
      Top = 39
      Width = 148
      Height = 15
      Caption = 'Resumen de la sesi'#243'n actual'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblFechaHora: TLabel
      Left = 880
      Top = 2
      Width = 107
      Height = 23
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      Caption = '--/--/---- --:--'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -17
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      ExplicitLeft = 777
    end
    object lblPendingSync: TLabel
      Left = 455
      Top = 7
      Width = 248
      Height = 20
      Cursor = crHandPoint
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'OF pendientes'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsUnderline]
      ParentFont = False
      Transparent = True
      Layout = tlCenter
      Visible = False
      OnClick = lblPendingSyncClick
      ExplicitLeft = 352
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
        4D31342032314331332E343437372032312031332032302E3535323320313320
        32305631324331332031312E343437372031332E343437372031312031342031
        314832304332302E353532332031312032312031312E34343737203231203132
        5632304332312032302E353532332032302E3535323320323120323020323148
        31345A4D3420313343332E343437373220313320332031322E35353233203320
        31325634433320332E343437373220332E343437373220332034203348313043
        31302E35353233203320313120332E3434373732203131203456313243313120
        31322E353532332031302E3535323320313320313020313348345A4D39203131
        5635483556313148395A4D3420323143332E343437373220323120332032302E
        35353233203320323056313643332031352E3434373720332E34343737322031
        3520342031354831304331302E353532332031352031312031352E3434373720
        31312031365632304331312032302E353532332031302E353532332032312031
        3020323148345A4D35203139483956313748355631395A4D3135203139483139
        5631334831355631395A4D3133203443313320332E34343737322031332E3434
        3737203320313420334832304332302E35353233203320323120332E34343737
        322032312034563843323120382E35353232382032302E353532332039203230
        20394831344331332E34343737203920313320382E3535323238203133203856
        345A4D31352035563748313956354831355A222F3E0D0A3C2F7376673E0D0A}
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Properties.ShowFocusRect = False
      Style.BorderStyle = ebsNone
      TabOrder = 0
      Transparent = True
      Height = 52
      Width = 56
    end
    object btnConfig: TcxButton
      Left = 970
      Top = 46
      Width = 24
      Height = 19
      Cursor = crHandPoint
      Hint = 'Configurar tarjetas'
      Anchors = [akTop, akRight]
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.SourceHeight = 16
      OptionsImage.Glyph.SourceWidth = 16
      OptionsImage.Glyph.Data = {
        89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
        610000002B744558745469746C650053657475703B437573746F6D697A3B4465
        7369676E3B53657474696E673B50726F70657274381FB5210000033849444154
        785E7D937D4C535718C69F7B7B4AE52355971095599D2B3A0264A6219A85AA03
        679832C3A21665A2F891CD124704D9206340746B46623019C6A82C565315043F
        96383F83124D86D3B9580BCC39C0E98A6C4080B60B850BB7F79E7BBC6D5AFE5A
        78935FCE93933CEF7DCFCDF3629AE25478154D484F57D5872FA3B2F6D29429C8
        17DF380ACA6BCEB3325B23DB576DDF116E14812BAEB6E3F38A93200060FBD2C2
        590ACAE2CABF6BBCAA50DAEF1919A8A18C59766C30833106FBF93B96DC5D158F
        E3E72CA800C7199F3C6CC93E62FBF43F6BF971C647C65D98987A65775E46C696
        9CF4ADC6C4C44EC6F0D192450930BC190F4561D9C9C9A91DF99B32F2ADDBD7BE
        976A7AFF27004412259048834040F2F8C72690B4643E9216CFE7BD3E3F348487
        2228282C58CB2F5E34175461B8FBB30B7DAF7ABD002049D2D4CFD1E4EEFA3A25
        39E55D5769610E2F49140A63E0390E924C43CF5025C40045D5B7F5CAD3F6472B
        DA1F5D730290B8A0796751ED368D56BB9968C8BAAAD23C4E1B45F0C7B3976868
        BA054234D8BE351B06430286863DA83BFEA332210AADA22034FFD97EAF890020
        4437C3B1273F4B1DDD0042087CFE71D41D6B46FF3FEECD248A7027CFE2C2A183
        56F01A82BD9F6DE4BD5E5FD6E973B7B2DC7FB92E11009C1C0884DEE71F9F84A4
        5050CA10131B0DDD0C5DB4362A4AD5B1102519E38208AA500C794621CB0104BD
        3C00F9E5F3AEA2AF0ED4B5EEAF3CC10607BD989C10B1735B0E92524D67826C5C
        BF1263C2243CBE51D86C2760B737B4F5B9BB4B010422E1D1A5993F5EBEA7E47B
        F9EFBE21F6C0D9C3DA1E77B1DFBBFB588F7B80B53FEB652D6D9DEC5AAB93ADB3
        942886B7D33201C4A8F0040053417C82B12C739549234C8AA1AF8D8CF830365B
        1FCC008646BC9839531F0AD5F2654BB9DE172FF603CEBC7796AE57A672C02816
        44C7EA70F3F62F68BD7D1F94D3B2A2BD9F700149467D7D239BA58F41DA3213A7
        D7C781CA745ED023530991244A1DBFDDD870E468C3AF0E47F3F5A71DF7B32684
        D1078303C370BBFF85E0F73DEC74B6655F6EBA78F5D40F0E57FF2BD71600A242
        2942B53AA718E1258909136B4ACF2D367F58C8CC6BACCC98F2410980B8E07DF8
        D4AA706F25AD997695A355DE0812D63CFEA75E03CFF56ADF743CC88500000000
        49454E44AE426082}
      OptionsImage.Layout = blGlyphTop
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      SpeedButtonOptions.Transparent = True
      TabOrder = 1
      OnClick = btnConfigClick
      ExplicitLeft = 867
    end
  end
  object pnlCards: TPanel
    Left = 0
    Top = 70
    Width = 1003
    Height = 714
    Align = alClient
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 1
    ExplicitTop = 71
    object pnlEmpresa: TPanel
      Left = 24
      Top = 24
      Width = 364
      Height = 140
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblEmpresaCap: TLabel
        Left = 16
        Top = 14
        Width = 48
        Height = 13
        Caption = 'EMPRESA'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblEmpresaNombre: TLabel
        Left = 112
        Top = 40
        Width = 248
        Height = 25
        AutoSize = False
        Caption = '--'
        EllipsisPosition = epEndEllipsis
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -16
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblEmpresaCodigo: TLabel
        Left = 112
        Top = 72
        Width = 248
        Height = 15
        AutoSize = False
        Caption = 'C'#243'digo: --'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Panel1: TPanel
        Left = 16
        Top = 31
        Width = 90
        Height = 65
        BevelOuter = bvNone
        Color = 15395562
        ParentBackground = False
        TabOrder = 0
        object Image1: TImage
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 84
          Height = 59
          Align = alClient
          Center = True
          Picture.Data = {
            0D546478536D617274496D61676589504E470D0A1A0A0000000D494844520000
            01680000016808030000004D3B91E70000011A504C5445000000B4403DFDAE47
            0B3442FCC24ADAAE49043142545042EDB849FDC34AFCC24AFFC44AC8A4490030
            42002F42365143C2A147013042082F42003042002F42063742003042003042ED
            3E3A002D42FEC34AF5BD4AD6AC49A18E474C5E44143F43837D469A89465E6845
            707345B99B47FFC54AFFC64AFF3F3AFF3839FF3839FF3839FF3839FD3839FF38
            39FF3839FF3839FF3839FF3839FF3839FF3839FF393BFF3839FF3738FD3839A0
            373DB7353CFDA546FF403CFFC74AFFC84AFDC24AFCC24AFF3536FC5355FA6367
            F6878CF0B4BCF39FA6F4969DF8757AFE4547F1AAB2EFC0C9EDD4DEEBE7F2EAEE
            F8E9F5FFE9F3FFEFCBD4ECDEE9FCC24AFCC24AFE6D3FFCC24AFE8942FF563DFC
            C24AFAC14A90343D52333F56333F7E343E978CC22C0000005E74524E53000410
            4DC7B513ACFFFFFFFFFF6F30FFFFC87EF4DFFF95FF09FFFFFFFFFFFFFFFFFFFF
            FFFFFFFF1B2B3B4C5E718192A3B5C9DCEDFEFFFFFFFFFEFFFFFFFF34EFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF75DBFF58FFFFAA91FFFFF5D98CA0600000
            000E0A4944415478DAECC1010D0000000130FA97D6C3FE070000000000000000
            00000000000000000000000000000000000000000000000000000000806F1D39
            F67105410C024114C67B27AD98C93FD1CD427DA80EE15F8A47537F465CDB555F
            3F186F3E4EF35277EBB61B6FC7591FFABA07A3CD1F05746A8DB6210BA0B75F71
            836D0F09743E8CB5F7FE24D0DF63ACB549044DCB610911342C87475641C7FDB2
            5228834EA41C0EB70E3A0A2A8542E8CCC9A1971042C70E4AA1149A73E13D2185
            4E2D268552684C0EBD4D62E87C50522885A6E4D08FA485C6E4B084161A92431F
            B21E3A8A13DE1C7A68C2C3C3EF3FB9E6A1DC380884E1EB27445A9331A8B7F4DE
            EBFBBFD669B157F61A990CA36B91BF7408F2E89B1D2DFCC98268C6BB8019C529
            CA4796AD533861C0A868B1B302310715CDBCAD0ED6C2662AA24391172AEE239D
            EB229808D7BAAEC7A8E8E1B7C391A0A2791C74B019293F4C0242BA99646B2196
            75D73A91349754511A18A411A7A2C5D7158839A8E85C98C814446F4A3206A4C5
            1A43D1A29D2697E4516A4E0486E8A1E7FFEBC22A1A3145A3ED346E452316D188
            217A777763E831877B45538298A1E83E152D46036F85BD458B748DF7178DF9FF
            80630EF747879C820B8BB0D7A303595F8556688A969BF13C219B894E4A20417F
            5297348F715D1EB754A1EFABA9681964F10C8F11D143DFE1ED88E5A20BC667D4
            CA6F450755CD1AC228C1A5F9BCE824ACC98185A3E834DA5F76601978E0F1195B
            61B7689F302F9AFB408DCF0459FA443423CB7445E3E3874045FFFBC0E373CB58
            F30538987078D8BC034787875F7AB44267D1002BE5D4AD4D745BD156D17DF3FF
            393FD411FA8137CD3170029C6ACE8073E04273095CC19BE6BAE566CAF5D5D9D1
            67D798A397689EA1E89E158DEC8CD10F7134D173A405BDEB08FDC01B1A4247B7
            0BDC519A815BFCA2B96FDE1E6E1F26BFD80C22B737E7074EAD70D72E9A21EF55
            74414573842D5474BD1047B1E8B1E1E9F109A18EC00F720B6F28C7CA6D63464B
            426692C0DAC35DF306D3F046C10173DC7C8DCB43A798C32ADA43C26ED1CA9B0E
            C88CEC3AB6D6107D41D58AAED690C8D7A8E797C9FD37B7DFB0A8F11E9CCD0D3D
            E01D5B402B7F0C7C8DAB4387FFF1B78A4E37916C51F46BDDA0BC5208348FA281
            A025E76D45D38962F2786120BA87B77FC9EDC5D835E63045E3B144E8379950D1
            A2CC816C932C04D11429F31A2B5A23DB898488FE98DC1CBBC61CA6680A116D9E
            0C65102F39828368AC68C20044375C8E9DF676EEA229529421B3895603157D7B
            73E8D00A7B8B964109CB56B1A26F4F1C620E8B688958444BB1196B679666A83A
            9AE10044379CBAB4424BA89421B1215AB60192A71806FF38566D211E23FBE878
            FE6F8903107DE6D80ADF0F958C5DC7A6C42593397A60A1EB94E5C032F48AA6AD
            D0FD08FE160762428693CE59C7009ED1B8BFB3311E891EA2EB3091B3281A70CF
            3A06BFEBC056D84734E755803147C856A7A2DDF7D19F3746263F7F91731EEA6E
            EA5814BEE74EF5B9BDA7F7DE8BD0145244AFC226ADBDFF838C65BCBDD8087B98
            D8F8CBF1AC5B410A7CFECF6269B3AD6438E8E3B35796A0CDC1FF95A3A107833A
            A43DE75EBC3C1E0CFA9B6F0D3D3C070CF4F13A474F6CD0075F466F079A5AA446
            97CF70D0172F4097CEB6BE9CFDAD3570C5B8FB8B042DD5427248448F0F9A0201
            D18B1796D310BE05EF8C98ED061668C1E5ACFBBCA25FD6E01A40500F64E97AFE
            429E2BFF0BECC7A7F6E3E8EB976815BDFA993B95386815841D4571E2A7F6C7C5
            3CA6CC3313DD1867921E50CAC778964A3EA6D224CA8B52CF55167994A452AD37
            BE40448F089AB5FD2FFEF8791B68386899555CD36AAACB5994A41DD498C754FA
            732A329DE1CC0C20E1E70CE3B5D7E628A517CFF4FCA68DCCDD67B127E580881E
            13B4217D9EB588B67674564DFBA4F32465C65A338F40E38C4E2C434AAFC63803
            ADD2A0985A2A8254ED3AA201FA74A33ED00BFDD1809EFCFD02F5A5CF9F31A04F
            DB22D0967A1D3DED55A573DF91C341439995C22A98F683967E8E1F90F99B6C9D
            FB724D447FBD2DE86B5431746BB1B3579723CBB7C1EBD7587141476D5D3D6BF6
            475FB10750753047EBCEDF842470F1717BE70134505136406C98814E6A500670
            A33A5957456F05DAE8EC52672CD24BC1E3241C316D1A980C71347D5A1DBB72B0
            A3A1B8035A25BADFD149D9A1ACF19F32913B8D6880C61E03C81EB18F27B63060
            8F0CC968C4472C3683AE001AB8BACBA1CC882103AD0C672B39300F590F51446F
            017A8FE28EA6482074E6189E0E24402F078AB666041AB0BACBA1F26A8C02B4F2
            8BE91474AB269C5B130B589F45F4C9040D47D77130571CE52C376B5F751C5D78
            695B824218AA429797E01802689586ADFBE8228BE737CF0A8D8955E64A3BA24F
            B2A3E98157522E5ED282D9140C32B70BDACC831C028D80C54F870F72D0418B69
            9EA48E9ACB49135E28DA117DB21DADDBC9AA541A972B32DA573C3A8A4E02C3D1
            E019CBCE52884820D084DFFC1DADDE8E844A234DD951E5DD5B3DBD7D108E9670
            4E5012B52A13CCD16B4103339F23324A5E389A55223A16D281DCC8B63422FA44
            3B1AA04127628FFA10D01AAE6584BC1A94713D37ACE844984A7EB19CAE5465DD
            FD60C07642AB0E80063AE213AC40EB4DA0D72C87782B44D54195085E792056F6
            151EBF1722FA601CDD2A15326B316C09A0110FA067A50A8196ABE4A842E17029
            37AFA61A0B048BE843CA685EFCD240565149112490C7AB0EBE1C62294441428E
            8EE85007AAA73542B3F9E0E39B5F1D4AD501A52B5BD5DE12347091AA5875A2A3
            2E519BB0A5B0668E164D446B789F75AF293B3A21FDF0E8E01C8DACA0AA980E01
            5B0334F221CF59C1A0A8415A64346301DA9D6D5A5BD1550D05DF3AB38DBE7EF5
            7ABF988FFFFDC6599BD118889764AA924063415BEFE830E0CB211D46311E10D5
            FA05D5AC6F6D2DA8ECC8DDAD231A3ABA09D47BC1EC3A10AB3A6CD05891681EEC
            CC41135FAF462420BCB51F57880E9C9F837639655C0EA3DB46343621DC7CF5E7
            FD70369889E700476B069ACB8E0E333B74696284D71273F10568CD40E3B61DA5
            0581CEDD9D4434B417D41360E68E467101C988C8F2E880FA1D2D138D1A5810F5
            58751D4D975B9BD11AB5DF4E221A59FD765CD467CEBE23CC431C2DF20AAB57DB
            D1BAAE8BC55FE6EFC002BDB2A30ED46A292C7D8046D56134B0EA40446FAFA3A3
            31514FCEBE7BCF316FAE3AA457F0871B6F865E4B29852A2C28A3D563BF8A1FF3
            BF55BB8E96111DEA645D1D6DC663B5BB88E6AEFEF0722437BF7738E6CD75B449
            57B0B3DAA48A249DAEA3C5CA8FA59FCE606EE668624997E77243EBA78088FEA2
            5103F350474B379C920205D07A73F7CE6093694ECB612BAE97A0B5D5EB40F39A
            2707DE95761CD140FD62B7A89FFD9B611E96D122616D8B01DD3BF85305CB92A4
            C891B4DD8C767374EF5CC92F16AE922314BB8F68E8E8D42E51AFC1BCB98E56FE
            72DDD7266AE5FF08DAB895444D5396D13C87793F5A8A58F7F6A39FEC2EA25157
            1FBDF8B813D413601EEE68A94452005430F81B16DD804649812B93A301DA2B56
            D56219A76A75EFD470C6B2314E444306F5EBE3C9F66F278E62583666B46AE4FA
            59C9290D72349A132AC11E1BEAE4B18CEEEE5ED2A1DFDC5CA649AE09330C8D88
            1E09F5DF8FCF6CFFAEBD590A4E4DE6F29320CA09B3395DD2871D1E1D78B343C8
            5B8E36ED41F402AB328F82647EEF19DD1B5FBD20A247FCD3F12E9D03EA1130F3
            9D4ABA1136571845826D0933DCC2AC2D4F1268D48232022DDD843CCF685A0720
            33AAF986A502E508227A24D07F5CBC0AD45BB434363A1A4D226DF532602AFC40
            EC6DBBDCD154A0697C156639BA098FD2BA2D7B9624EF458F0AFAF4E98B57BF3D
            FE668B96C66047EB9E7D9D3941411DDD1103ADC9D1544A032CCFE84622401FD0
            BA791938562F7A44D07F34A8CF7E33829B594693D8FF86E0CCBF61817A1C8D95
            0EDB152C47635703038CEA3D1092FF311D23836E505FF9F1EC648B96C62047E3
            735298623B38A243732ABCED0CD05ECD771ED8196D249DA4E03726CD12074244
            8F0BDAA0FEEDF2BF07147B672CCC4333DADE3B5B66BE940ED471FE66470B11B2
            F2DC7234497951D913CF11CD218947A746064DA83FB96F807A784B63B8A3A1AA
            9A96B3C817F8AC03F647570C343AFE9529A201DADAA7AE849FD5D30ABEAEA675
            867B8F1DD1004DFAE448A01ED0A01B2A15D55C459167816FFFCE28CC632A1AD0
            391D670D6891E618379201CD987536C548E1056151368F555984816763FE87B8
            B337D0068AFBFE1DB27A2B3743A9D751EA3A4AC90DF3B8DC0557D6A0666784F5
            EBEDFA5E89D44F82B9123F150A985944EF0FB411505B2D8DCF95E242303309CC
            E3A21E05FAD3EC8CB4EE23375E7DC0EFB41F1B34698EBAA741A79C83D6FDAFF6
            0E1AA8F17672C89811D1FB072DE7A8FFDDC27CB84244EF153424A5417DF89811
            D17B06CD51CF31CBFFB4771728960531004553ADD8B8A2837F77DBCBC8FEB731
            5EED66A1A977CE122E218F7CDD5456F41385AE4FE8F6AD8799A13B6CD96F20B4
            152D743509A133AC8742A758F45A086D73085D075AE804EBD530844EB01C85D0
            4F6F3D1F4476E85DE7AC97F3D15EF61FA67EF9D635DFC783FEE788E4D0F5EF57
            9A97FB1FAD3574877D2C42A7781B19847EB7DF50682B5AE8776F4A4BA1AD6813
            BDDF44682B5AE8BAA25B0A6D459BE8FD4854F65F3C7F3FBE3EBE1FC76F8F5243
            9778F6F6168FFC7ECA623A1EF43E07E7F4968FD778399F0CFB7BC165FAAB4789
            BC5C4C4706F93A83D5C397C56C32EC7F8E125C63B87E40E3F572FE7B9025BE85
            D10306793CB42C6EAB8C3777B7FA3DC8FDBD12D6C5ED4DEF31C87F9E7A22DF49
            99DD6990277F0659E2BBFB3C7787641D86F97788C330FF0E7118D63B84A73B0C
            DD218F6FB84EB943185DB843FE0C72099EE430AC77084F645AEF90A73CA82963
            839CE37309000000000000000000000000000000000000000000000000000000
            00000000000000000000B8BF9F8D6A3C12999AFEB80000000049454E44AE4260
            82}
          Proportional = True
          Stretch = True
          ExplicitTop = 2
        end
      end
    end
    object pnlProyecto: TPanel
      Left = 402
      Top = 24
      Width = 280
      Height = 140
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblProyectoCap: TLabel
        Left = 16
        Top = 14
        Width = 95
        Height = 13
        Caption = 'PROYECTO ACTIVO'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblProyectoNombre: TLabel
        Left = 16
        Top = 40
        Width = 248
        Height = 25
        AutoSize = False
        Caption = '--'
        EllipsisPosition = epEndEllipsis
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -16
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblProyectoTipo: TLabel
        Left = 16
        Top = 72
        Width = 248
        Height = 15
        AutoSize = False
        Caption = 'Tipo: --'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlUsuario: TPanel
      Left = 696
      Top = 24
      Width = 280
      Height = 140
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 2
      object lblUsuarioCap: TLabel
        Left = 16
        Top = 14
        Width = 47
        Height = 13
        Caption = 'USUARIO'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblUsuarioNombre: TLabel
        Left = 16
        Top = 40
        Width = 248
        Height = 25
        AutoSize = False
        Caption = '--'
        EllipsisPosition = epEndEllipsis
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -16
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblUsuarioRol: TLabel
        Left = 16
        Top = 72
        Width = 248
        Height = 15
        AutoSize = False
        Caption = 'Rol: --'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlMetricas: TPanel
      Left = 24
      Top = 184
      Width = 872
      Height = 150
      BevelOuter = bvNone
      Color = 15856098
      ParentBackground = False
      TabOrder = 3
      object lblMetricasCap: TLabel
        Left = 16
        Top = 14
        Width = 70
        Height = 13
        Caption = 'CONTADORES'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblCapCalendarios: TLabel
        Left = 16
        Top = 44
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Calendarios:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValCalendarios: TLabel
        Left = 160
        Top = 44
        Width = 80
        Height = 17
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValCalendariosClick
      end
      object lblCapCentros: TLabel
        Left = 16
        Top = 68
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Centros:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValCentros: TLabel
        Left = 160
        Top = 68
        Width = 80
        Height = 17
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValCentrosClick
      end
      object lblCapAreas: TLabel
        Left = 16
        Top = 92
        Width = 140
        Height = 17
        AutoSize = False
        Caption = #193'reas:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValAreas: TLabel
        Left = 160
        Top = 92
        Width = 80
        Height = 17
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValAreasClick
      end
      object lblCapTurnos: TLabel
        Left = 260
        Top = 44
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Turnos:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValTurnos: TLabel
        Left = 404
        Top = 44
        Width = 80
        Height = 17
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValTurnosClick
      end
      object lblCapCapacitaciones: TLabel
        Left = 260
        Top = 68
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Capacitaciones:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValCapacitaciones: TLabel
        Left = 404
        Top = 68
        Width = 80
        Height = 17
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValCapacitacionesClick
      end
      object lblCapOperarios: TLabel
        Left = 260
        Top = 92
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Operarios:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValOperarios: TLabel
        Left = 404
        Top = 92
        Width = 80
        Height = 17
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValOperariosClick
      end
      object lblCapDepartamentos: TLabel
        Left = 16
        Top = 116
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Departamentos:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblValDepartamentos: TLabel
        Left = 160
        Top = 116
        Width = 80
        Height = 17
        Cursor = crHandPoint
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold, fsUnderline]
        ParentFont = False
        OnClick = lblValDepartamentosClick
      end
    end
    object pnlProyectoActivo: TPanel
      Left = 24
      Top = 354
      Width = 872
      Height = 200
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 4
      object lblProyectoActivoCap: TLabel
        Left = 16
        Top = 14
        Width = 166
        Height = 13
        Caption = 'PROYECTO ACTIVO PLANIFICADO'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblCapFechaInicio: TLabel
        Left = 16
        Top = 44
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Fecha inicio:'
      end
      object lblValFechaInicio: TLabel
        Left = 160
        Top = 44
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapFechaFin: TLabel
        Left = 16
        Top = 64
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Fecha fin:'
      end
      object lblValFechaFin: TLabel
        Left = 160
        Top = 64
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapFechaBloqueo: TLabel
        Left = 16
        Top = 84
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Fecha bloqueo:'
      end
      object lblValFechaBloqueo: TLabel
        Left = 160
        Top = 84
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapNodos: TLabel
        Left = 16
        Top = 108
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Nodos planificados:'
      end
      object lblValNodos: TLabel
        Left = 160
        Top = 108
        Width = 300
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapOFs: TLabel
        Left = 16
        Top = 128
        Width = 140
        Height = 17
        AutoSize = False
        Caption = #211'rdenes de fabricaci'#243'n:'
      end
      object lblValOFs: TLabel
        Left = 160
        Top = 128
        Width = 300
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapPedidos: TLabel
        Left = 16
        Top = 148
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'Pedidos:'
      end
      object lblValPedidos: TLabel
        Left = 160
        Top = 148
        Width = 300
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapCentrosUsados: TLabel
        Left = 480
        Top = 44
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Centros utilizados:'
      end
      object lblValCentrosUsados: TLabel
        Left = 644
        Top = 44
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapOperariosAsignados: TLabel
        Left = 480
        Top = 64
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Operarios asignados:'
      end
      object lblValOperariosAsignados: TLabel
        Left = 644
        Top = 64
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapDuracionTotal: TLabel
        Left = 480
        Top = 92
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Duraci'#243'n total planificada:'
      end
      object lblValDuracionTotal: TLabel
        Left = 644
        Top = 92
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapDependencias: TLabel
        Left = 480
        Top = 112
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Dependencias:'
      end
      object lblCapMarcadores: TLabel
        Left = 480
        Top = 132
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'Marcadores:'
      end
      object lblValMarcadores: TLabel
        Left = 644
        Top = 132
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblValDependencias: TLabel
        Left = 644
        Top = 112
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapOFsPendientes: TLabel
        Left = 480
        Top = 152
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'OF pendientes ERP:'
      end
      object lblValOFsPendientes: TLabel
        Left = 644
        Top = 152
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCapOTsPendientes: TLabel
        Left = 480
        Top = 172
        Width = 160
        Height = 17
        AutoSize = False
        Caption = 'OT pendientes ERP:'
      end
      object lblValOTsPendientes: TLabel
        Left = 644
        Top = 172
        Width = 200
        Height = 17
        AutoSize = False
        Caption = '--'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object pnlAcciones: TPanel
      Left = 24
      Top = 576
      Width = 872
      Height = 41
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 5
    end
  end
  object TimerReloj: TTimer
    OnTimer = TimerRelojTimer
    Left = 840
    Top = 96
  end
end
