object frmVistaGantt: TfrmVistaGantt
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Vista Gantt'
  ClientHeight = 600
  ClientWidth = 1130
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlRoot: TPanel
    Left = 0
    Top = 273
    Width = 1130
    Height = 327
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object pnlCentros: TPanel
      Left = 0
      Top = 0
      Width = 465
      Height = 286
      Align = alLeft
      BevelOuter = bvNone
      Caption = 'pnlCentros'
      TabOrder = 0
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 465
        Height = 48
        Align = alTop
        BevelOuter = bvNone
        Color = 15395562
        ParentBackground = False
        TabOrder = 0
        DesignSize = (
          465
          48)
        object LblIndicadores: TLabel
          Left = 253
          Top = 27
          Width = 212
          Height = 13
          Anchors = [akTop, akRight]
          AutoSize = False
          Caption = 'Indicadores'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 8220514
          Font.Height = -11
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
          Visible = False
        end
        object Shape1: TShape
          Left = 0
          Top = 47
          Width = 465
          Height = 1
          Align = alBottom
          Brush.Color = clSilver
          Pen.Color = clSilver
          ExplicitTop = 41
          ExplicitWidth = 226
        end
        object Shape2: TShape
          Left = 464
          Top = 0
          Width = 1
          Height = 47
          Align = alRight
          Brush.Color = clSilver
          Pen.Color = clSilver
          ExplicitLeft = 0
          ExplicitTop = 46
          ExplicitHeight = 226
        end
        object Label12: TLabel
          Left = 10
          Top = 20
          Width = 136
          Height = 21
          Caption = 'Centros de trabajo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 8220514
          Font.Height = -16
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object btnKPIVisible: TcxButton
          Left = 418
          Top = 26
          Width = 20
          Height = 19
          Hint = 'Estad'#237'sticas del rango visible'
          Anchors = [akTop, akRight]
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'DevExpressStyle'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 16
          OptionsImage.Glyph.SourceWidth = 16
          OptionsImage.Glyph.Data = {
            89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
            610000001D744558745469746C6500486F72697A6F6E74616C3B416C69676E3B
            43656E74657207359FCF0000019D49444154785E7553B18A145110AC99F3100D
            8C4C8DCD36BADC45FFE01233533131158C8C2E315BB83F1013631144B95BC1F8
            0233233F4061239DDBE9AE3A5F77F3F658B837344C57D355F56A98017986AA7A
            BFF9D45C556ACD78FAFEE2EB388E4B14FA67FB1A24413AE80E9747FFE0DE0A82
            82C1CDD72F9F1D3DB9D518FF9FE5F3A78B2EB1FAE8787C749C8D104B9FBE7FC0
            8BE345AD0BA7EF2E1E35F1207067484FB3A72F0994E3D7E65B70DCBFFB30B07F
            DB9CDF393C8053719D4600BA524C2929320824064E5A60D2EEF266390B074642
            F1E494521124669A0BDB0999FBCE811BFBE2108A84CBE064F51658ED07B15912
            8CE1C03DD5992AA4D2B6088A30CE8165368052B43B185AA34A5B1A82C03977CB
            2C02564612D241CFC0BCB34375056E810A71F629307411C1BC3BC844D5BF02AF
            3948DC3543BE17626570DD414FDDC924601178069A53807B0E86D650C15C4E94
            AAB5E0B49CC74E0A5588181BD41D64F5100F86DBD92B3F23CBBEB772F6107D9A
            FE9EBF3AF9BC54A5FC7BDAE0E78F33F4538B6FDE7EE9BFE27C39AD01D8502E0E
            A36EFE95F7710130009757B8A1A15B551D6BC50000000049454E44AE426082}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.Transparent = True
          TabOrder = 0
          Visible = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnKPIVisibleClick
        end
        object btnKPIAll: TcxButton
          Left = 441
          Top = 26
          Width = 20
          Height = 19
          Hint = 'Estad'#237'sticas desde hoy hasta fin'
          Anchors = [akTop, akRight]
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'DevExpressStyle'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.Data = {
            89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
            610000001C744558745469746C6500486F72697A6F6E74616C3B416C69676E3B
            5269676874C371E1FA0000017F49444154785E7593314A44410C86FF792A82B5
            77B0B3B277D11BD87804C10B081EC0C252B0D4523C818520BA7A000B3B2B2FB0
            B095BCDD99FCD10999305B6CD8BC4966DEFBF325C32698A1AE5DBCCEE25C9BD7
            64B87DF87C19866102001A8F1624CCF2254882145004A28252647A7DFE71BC59
            15FF6D7276BA8F30C58ADD3C098E0E4EE24CA1B87FBC3BACC54D4084763066E9
            8BC7A2AAA00A7EE6EFB6B7BBB307AA61A62A008A25D0C6AFDE5C4B491350A56D
            9125BE3182421A96F6953B023A81AA5A5E3483D21148B1160C2B39B8135A4C12
            A2054222350232045211EF9D0A2620A983F89354C356258C8019D211A44AA03E
            5DD554E3B84275016106B5096608FB1914F149C735C504536B814BC087986584
            0A8300A512C4E06857E032AB04DE826810A49EC03CC015C121A409902E20055C
            1110826A044EA2407222CF4573B426760B301BEA1204E1AD5DCBA3858DB4EDB3
            2AA0308628E3F8FB7671F53C69D37780A8385BCCF1FDF58ADEF29253002539C5
            967B5AFF17EECD940B80C51F1FAD67EBD57E3C2A0000000049454E44AE426082}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.Transparent = True
          TabOrder = 1
          Visible = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnKPIAllClick
        end
        object btnShowCentrosKPI: TcxButton
          Left = 407
          Top = 2
          Width = 27
          Height = 19
          Hint = 'Ver indicadores'
          Anchors = [akTop, akRight]
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'DevExpressStyle'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 12
          OptionsImage.Glyph.SourceWidth = 12
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
            4331433B7D262331333B262331303B2623393B2E426C61636B7B66696C6C3A23
            3732373237323B7D262331333B262331303B2623393B2E426C75657B66696C6C
            3A233131373744373B7D262331333B262331303B2623393B2E57686974657B66
            696C6C3A234646464646463B7D262331333B262331303B2623393B2E47726565
            6E7B66696C6C3A233033394332333B7D262331333B262331303B2623393B2E73
            74307B6F7061636974793A302E37353B7D262331333B262331303B2623393B2E
            7374317B6F7061636974793A302E353B7D262331333B262331303B2623393B2E
            7374327B6F7061636974793A302E32353B7D262331333B262331303B2623393B
            2E7374337B66696C6C3A234646423131353B7D3C2F7374796C653E0D0A3C672F
            3E0D0A3C672069643D224368617274506F696E7473223E0D0A09093C72656374
            20783D2232342220793D22322220636C6173733D2259656C6C6F772220776964
            74683D223622206865696768743D223236222F3E0D0A09093C7061746820636C
            6173733D22477265656E2220643D224D302C32306836763848305632307A204D
            382C3134683676313448385631347A204D31362C386836763230682D3656387A
            222F3E0D0A093C2F673E0D0A3C2F7376673E0D0A}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.CanBeFocused = False
          TabOrder = 2
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnShowCentrosKPIClick
        end
        object btnConfigCentros: TcxButton
          Left = 439
          Top = 2
          Width = 20
          Height = 19
          Hint = 'Configurar centros'
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
          TabOrder = 3
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnConfigCentrosClick
        end
      end
    end
    object pnlGanttContainer: TPanel
      Left = 465
      Top = 0
      Width = 665
      Height = 286
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlGanttContainer'
      TabOrder = 1
      OnResize = pnlGanttContainerResize
    end
    object pnlSummary: TPanel
      Left = 0
      Top = 286
      Width = 1130
      Height = 41
      Align = alBottom
      BevelOuter = bvNone
      Caption = 'pnlSummary'
      TabOrder = 2
      object pnlSummaryToolbar: TPanel
        Left = 0
        Top = 0
        Width = 475
        Height = 41
        Align = alLeft
        BevelOuter = bvNone
        Color = 15395562
        ParentBackground = False
        TabOrder = 0
        object Shape4: TShape
          Left = 0
          Top = 40
          Width = 475
          Height = 1
          Align = alBottom
          Brush.Color = clSilver
          Pen.Color = clSilver
          ExplicitTop = 41
          ExplicitWidth = 226
        end
        object Shape5: TShape
          Left = 474
          Top = 1
          Width = 1
          Height = 39
          Align = alRight
          Brush.Color = clSilver
          Pen.Color = clSilver
          ExplicitLeft = 0
          ExplicitTop = 46
          ExplicitHeight = 226
        end
        object Label22: TLabel
          Left = 9
          Top = 6
          Width = 60
          Height = 21
          Caption = 'Sumario'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 8220514
          Font.Height = -16
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object Shape6: TShape
          Left = 0
          Top = 0
          Width = 475
          Height = 1
          Align = alTop
          Brush.Color = clSilver
          Pen.Color = clSilver
          ExplicitTop = 41
          ExplicitWidth = 226
        end
        object btnS3: TcxButton
          AlignWithMargins = True
          Left = 419
          Top = 9
          Width = 24
          Height = 23
          Margins.Top = 8
          Margins.Right = 1
          Margins.Bottom = 8
          Align = alRight
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Office2010Silver'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 16
          OptionsImage.Glyph.SourceWidth = 16
          OptionsImage.Glyph.Data = {
            3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
            462D38223F3E0D0A3C7376672076657273696F6E3D22312E31222069643D2241
            7265612220786D6C6E733D22687474703A2F2F7777772E77332E6F72672F3230
            30302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F7777772E
            77332E6F72672F313939392F786C696E6B2220783D223070782220793D223070
            78222076696577426F783D2230203020333220333222207374796C653D22656E
            61626C652D6261636B67726F756E643A6E6577203020302033322033323B2220
            786D6C3A73706163653D227072657365727665223E262331333B262331303B3C
            7374796C6520747970653D22746578742F6373732220786D6C3A73706163653D
            227072657365727665223E2E426C75657B66696C6C3A233131373744373B7D26
            2331333B262331303B2623393B2E59656C6C6F777B66696C6C3A234646423131
            353B7D262331333B262331303B2623393B2E7374307B6F7061636974793A302E
            353B7D3C2F7374796C653E0D0A3C706F6C79676F6E20636C6173733D2259656C
            6C6F772220706F696E74733D22322C31322031322C32302033302C342033302C
            323820322C323820222F3E0D0A3C6720636C6173733D22737430223E0D0A0909
            3C706F6C79676F6E20636C6173733D22426C75652220706F696E74733D22322C
            32322031342C31302033302C31362033302C323820322C3238202623393B222F
            3E0D0A093C2F673E0D0A3C706F6C79676F6E20636C6173733D22426C75652220
            706F696E74733D2231322C323020372E362C31362E3420322C323220322C3238
            2033302C32382033302C31362032302E352C31322E3420222F3E0D0A3C2F7376
            673E0D0A}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.GroupIndex = 1
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          TabOrder = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnS4: TcxButton
          AlignWithMargins = True
          Left = 447
          Top = 9
          Width = 24
          Height = 23
          Margins.Top = 8
          Margins.Bottom = 8
          Align = alRight
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Office2010Silver'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 16
          OptionsImage.Glyph.SourceWidth = 16
          OptionsImage.Glyph.Data = {
            3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
            462D38223F3E0D0A3C7376672076657273696F6E3D22312E31222069643D2253
            656C6563745461626C65526F772220786D6C6E733D22687474703A2F2F777777
            2E77332E6F72672F323030302F7376672220786D6C6E733A786C696E6B3D2268
            7474703A2F2F7777772E77332E6F72672F313939392F786C696E6B2220783D22
            3070782220793D22307078222076696577426F783D2230203020333220333222
            207374796C653D22656E61626C652D6261636B67726F756E643A6E6577203020
            302033322033323B2220786D6C3A73706163653D227072657365727665223E26
            2331333B262331303B3C7374796C6520747970653D22746578742F6373732220
            786D6C3A73706163653D227072657365727665223E2E426C75657B66696C6C3A
            233131373744373B7D262331333B262331303B2623393B2E426C61636B7B6669
            6C6C3A233732373237323B7D262331333B262331303B2623393B2E7374307B6F
            7061636974793A302E353B7D3C2F7374796C653E0D0A3C7061746820636C6173
            733D22426C75652220643D224D31302C31384832762D3668385631387A204D32
            302C3132682D38763668385631327A204D33302C3132682D3876366838563132
            7A222F3E0D0A3C6720636C6173733D22737430223E0D0A09093C706174682063
            6C6173733D22426C61636B2220643D224D31302C31304832563468385631307A
            204D32302C34682D387636683856347A204D33302C34682D387636683856347A
            204D31302C32304832763668385632307A204D32302C3230682D387636683856
            32307A204D33302C3230682D38763668385632307A222F3E0D0A093C2F673E0D
            0A3C2F7376673E0D0A}
          OptionsImage.Layout = blGlyphBottom
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.GroupIndex = 1
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          SpeedButtonOptions.Down = True
          TabOrder = 1
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnS1: TcxButton
          AlignWithMargins = True
          Left = 363
          Top = 9
          Width = 24
          Height = 23
          Margins.Top = 8
          Margins.Right = 1
          Margins.Bottom = 8
          Align = alRight
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Office2010Silver'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 16
          OptionsImage.Glyph.SourceWidth = 16
          OptionsImage.Glyph.Data = {
            89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
            610000001974455874536F6674776172650041646F626520496D616765526561
            647971C9653C00000032744558745469746C6500437573746F6D65723B456D70
            6C6F7965653B506572736F6E3B436F6E746163743B557365723B436C69656E74
            7E1136E8000000AC49444154785EA5D1310AC2501084E114923EC750B04915AB
            681FCF90BB58A5F1103984602F829E2127D03A1626C838C8146121CFD514DF2B
            86E56F5E046092CFB3DD1DAD8CCEF4900BE5E6663430A31BC1B853EC09CC0923
            169EC03A10D8780255205079022B7AD980B6EC6B404E36A02DF20672EA08D279
            BED12AE92AA5365720A1BDF9F3585B120AA474A09E40352DA5D6D6EB26B58182
            9E040FDD16C34043F851330CB47F045A0530C91BA77C3FB55043EFF400000000
            49454E44AE426082}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.GroupIndex = 1
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          TabOrder = 2
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnS2: TcxButton
          AlignWithMargins = True
          Left = 391
          Top = 9
          Width = 24
          Height = 23
          Margins.Top = 8
          Margins.Right = 1
          Margins.Bottom = 8
          Align = alRight
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Office2010Silver'
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
            63653D227072657365727665223E2E426C75657B66696C6C3A23313137374437
            3B7D262331333B262331303B2623393B2E477265656E7B66696C6C3A23303339
            4332333B7D262331333B262331303B2623393B2E59656C6C6F777B66696C6C3A
            234646423131353B7D262331333B262331303B2623393B2E426C61636B7B6669
            6C6C3A233732373237323B7D262331333B262331303B2623393B2E5768697465
            7B66696C6C3A234646464646463B7D262331333B262331303B2623393B2E5265
            647B66696C6C3A234431314331433B7D262331333B262331303B2623393B2E73
            74307B6F7061636974793A302E37353B7D3C2F7374796C653E0D0A3C67206964
            3D224575726F5F315F223E0D0A09093C7061746820636C6173733D22426C7565
            2220643D224D32302C3234632D332C302D352E352D312E362D362E392D344832
            30762D32682D372E37632D302E322D302E362D302E332D312E332D302E332D32
            73302E312D312E342C302E332D32483230762D32682D362E3963312E342D322E
            342C342D342C362E392D3420202623393B2623393B63322C302C332E382C302E
            372C352E322C312E394C32382C372E314332352E392C352E322C32332E312C34
            2C32302C34632D352E322C302D392E372C332E332D31312E332C384834763268
            342E3243382E312C31342E372C382C31352E332C382C313673302E312C312E33
            2C302E322C324834763268342E3720202623393B2623393B63312E362C342E37
            2C362E312C382C31312E332C3863332E312C302C352E392D312E322C382D332E
            316C2D322E382D322E384332332E382C32332E332C32322C32342C32302C3234
            7A222F3E0D0A093C2F673E0D0A3C2F7376673E0D0A}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.GroupIndex = 1
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          TabOrder = 3
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1130
    Height = 273
    Align = alTop
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 1
    object pnlToolbar: TPanel
      Left = 0
      Top = 118
      Width = 1130
      Height = 109
      Align = alTop
      Color = clSilver
      ParentBackground = False
      TabOrder = 0
      Visible = False
      DesignSize = (
        1130
        109)
      object Label1: TLabel
        Left = 276
        Top = 7
        Width = 41
        Height = 15
        Caption = 'Centros'
      end
      object Label2: TLabel
        Left = 339
        Top = 7
        Width = 48
        Height = 15
        Caption = 'Total OFs'
      end
      object Label3: TLabel
        Left = 11
        Top = 7
        Width = 95
        Height = 15
        Caption = 'Fecha Inicio Gantt'
      end
      object Label4: TLabel
        Left = 138
        Top = 7
        Width = 80
        Height = 15
        Caption = 'Fecha fin Gantt'
      end
      object Label5: TLabel
        Left = 765
        Top = 6
        Width = 35
        Height = 15
        Anchors = [akTop, akRight]
        Caption = 'Buscar'
      end
      object Label7: TLabel
        Left = 606
        Top = 63
        Width = 78
        Height = 15
        Anchors = [akTop, akRight]
        Caption = 'Zoom timeline'
      end
      object lblUndoCount: TLabel
        Left = 11
        Top = 76
        Width = 23
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblRedoCount: TLabel
        Left = 33
        Top = 76
        Width = 23
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object btnRefresh: TButton
        Left = 997
        Top = 22
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Refrescar'
        TabOrder = 0
        OnClick = btnRefreshClick
      end
      object spCentros: TcxSpinEdit
        Left = 276
        Top = 23
        Properties.AssignedValues.MinValue = True
        Properties.ImmediatePost = True
        TabOrder = 1
        Value = 3
        Width = 57
      end
      object cxSpinEdit2: TcxSpinEdit
        Left = 339
        Top = 23
        Properties.AssignedValues.MinValue = True
        Properties.ImmediatePost = True
        TabOrder = 2
        Value = 30
        Width = 66
      end
      object dtFechaInicioGantt: TcxDateEdit
        Left = 9
        Top = 23
        Properties.ShowTime = False
        TabOrder = 3
        Width = 121
      end
      object dtFechaFinGantt: TcxDateEdit
        Left = 136
        Top = 23
        Properties.ShowTime = False
        TabOrder = 4
        Width = 121
      end
      object SearchBox1: TSearchBox
        Left = 765
        Top = 23
        Width = 145
        Height = 23
        Anchors = [akTop, akRight]
        TabOrder = 5
        Text = 'SearchBox1'
        OnInvokeSearch = SearchBox1InvokeSearch
      end
      object RadioButton1: TRadioButton
        Left = 822
        Top = 6
        Width = 40
        Height = 17
        Anchors = [akTop, akRight]
        Caption = 'OF'
        Checked = True
        TabOrder = 6
        TabStop = True
      end
      object RadioButton2: TRadioButton
        Left = 868
        Top = 6
        Width = 40
        Height = 17
        Anchors = [akTop, akRight]
        Caption = 'OT'
        TabOrder = 7
      end
      object Button3: TButton
        Left = 914
        Top = 22
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'X'
        TabOrder = 8
        OnClick = Button3Click
      end
      object Button4: TButton
        Left = 938
        Top = 22
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = '<'
        TabOrder = 9
        OnClick = Button4Click
      end
      object Button5: TButton
        Left = 962
        Top = 22
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = '>'
        TabOrder = 10
        OnClick = Button5Click
      end
      object Button6: TButton
        Left = 411
        Top = 21
        Width = 75
        Height = 25
        Caption = 'Recrear Raw'
        TabOrder = 11
      end
      object Button8: TButton
        Tag = 1
        Left = 606
        Top = 78
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'H'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 12
        OnClick = Button8Click
      end
      object Button9: TButton
        Tag = 2
        Left = 630
        Top = 78
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'D'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 13
      end
      object Button10: TButton
        Tag = 3
        Left = 654
        Top = 78
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'S'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 14
      end
      object Button11: TButton
        Tag = 4
        Left = 678
        Top = 78
        Width = 25
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'M'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 15
      end
      object ComboBox1: TComboBox
        Left = 819
        Top = 80
        Width = 253
        Height = 23
        Style = csDropDownList
        Anchors = [akTop, akRight]
        ItemIndex = 1
        TabOrder = 16
        Text = 'Solo ver dependencias del seleccionado'
        OnChange = ComboBox1Change
        Items.Strings = (
          'Ver todas las dependencias'
          'Solo ver dependencias del seleccionado'
          'Nunca ver dependencias')
      end
      object btnUndo: TButton
        Tag = 1
        Left = 9
        Top = 52
        Width = 25
        Height = 25
        Caption = 'Undo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 17
        OnClick = btnUndoClick
      end
      object btnRedo: TButton
        Tag = 1
        Left = 33
        Top = 52
        Width = 25
        Height = 25
        Caption = 'Redo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 18
        OnClick = btnRedoClick
      end
      object Button12: TButton
        Tag = 1
        Left = 59
        Top = 52
        Width = 39
        Height = 25
        Caption = 'Check'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 19
        OnClick = Button12Click
      end
      object Button25: TButton
        Left = 710
        Top = 21
        Width = 51
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'BUSCAR'
        TabOrder = 20
      end
      object Button26: TButton
        Left = 997
        Top = 3
        Width = 75
        Height = 20
        Anchors = [akTop, akRight]
        Caption = 'bbdd Connect'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 21
      end
      object Panel5: TPanel
        Left = 411
        Top = 52
        Width = 36
        Height = 41
        BevelOuter = bvNone
        Color = 7699523
        ParentBackground = False
        TabOrder = 22
      end
      object Panel16: TPanel
        Left = 548
        Top = 50
        Width = 38
        Height = 41
        BevelOuter = bvNone
        Color = 9404016
        ParentBackground = False
        TabOrder = 23
      end
      object Panel17: TPanel
        Left = 506
        Top = 50
        Width = 40
        Height = 41
        BevelOuter = bvNone
        Color = 8220514
        ParentBackground = False
        TabOrder = 24
      end
      object Panel18: TPanel
        Left = 381
        Top = 52
        Width = 31
        Height = 41
        BevelOuter = bvNone
        Color = 7041597
        ParentBackground = False
        TabOrder = 25
      end
      object Panel19: TPanel
        Left = 356
        Top = 52
        Width = 31
        Height = 41
        BevelOuter = bvNone
        Color = 3553567
        ParentBackground = False
        TabOrder = 26
      end
      object Panel20: TPanel
        Left = 464
        Top = 50
        Width = 40
        Height = 41
        BevelOuter = bvNone
        Color = 6313290
        ParentBackground = False
        TabOrder = 27
      end
    end
    object Panel3: TPanel
      Left = 0
      Top = 227
      Width = 1130
      Height = 50
      Align = alTop
      Color = 15395562
      ParentBackground = False
      TabOrder = 1
      Visible = False
      DesignSize = (
        1130
        50)
      object Label18: TLabel
        Left = 113
        Top = 4
        Width = 20
        Height = 15
        Caption = 'OFs'
      end
      object Panel6: TPanel
        Left = 691
        Top = 1
        Width = 73
        Height = 48
        Align = alRight
        TabOrder = 0
        object Label11: TLabel
          Left = 1
          Top = 1
          Width = 71
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Nodos modificados'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
        end
        object lblModified: TLabel
          Left = 1
          Top = 25
          Width = 71
          Height = 16
          Cursor = crHandPoint
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = lblModifiedClick
        end
      end
      object Panel7: TPanel
        Left = 764
        Top = 1
        Width = 73
        Height = 48
        Align = alRight
        TabOrder = 1
        object Label13: TLabel
          Left = 1
          Top = 1
          Width = 71
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Estado Normal'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
        end
        object lblNormal: TLabel
          Left = 1
          Top = 25
          Width = 71
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object Panel8: TPanel
        Left = 837
        Top = 1
        Width = 73
        Height = 48
        Align = alRight
        TabOrder = 2
        object Label14: TLabel
          Left = 1
          Top = 1
          Width = 71
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Estado Amarillo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
        end
        object lblYellow: TLabel
          Left = 1
          Top = 25
          Width = 71
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object Panel9: TPanel
        Left = 910
        Top = 1
        Width = 73
        Height = 48
        Align = alRight
        TabOrder = 3
        object Label15: TLabel
          Left = 1
          Top = 1
          Width = 71
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Estado Naranja'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
        end
        object lblOrange: TLabel
          Left = 1
          Top = 25
          Width = 71
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object Panel10: TPanel
        Left = 983
        Top = 1
        Width = 73
        Height = 48
        Align = alRight
        TabOrder = 4
        object Label16: TLabel
          Left = 1
          Top = 1
          Width = 71
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Estado Rojo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
        end
        object lblRed: TLabel
          Left = 1
          Top = 25
          Width = 71
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object Panel11: TPanel
        Left = 1056
        Top = 1
        Width = 73
        Height = 48
        Align = alRight
        TabOrder = 5
        object Label17: TLabel
          Left = 1
          Top = 1
          Width = 71
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Estado Verde'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
        end
        object lblGreen: TLabel
          Left = 1
          Top = 25
          Width = 71
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object Button21: TButton
        Left = 110
        Top = 19
        Width = 21
        Height = 25
        Caption = '<'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 6
        OnClick = Button21Click
      end
      object Button22: TButton
        Left = 130
        Top = 19
        Width = 21
        Height = 25
        Caption = '>'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 7
        OnClick = Button22Click
      end
      object Button2: TButton
        Left = 418
        Top = 6
        Width = 75
        Height = 19
        Anchors = [akTop, akRight]
        Caption = 'OF inversa'
        TabOrder = 8
        OnClick = Button2Click
      end
      object Button23: TButton
        Left = 418
        Top = 25
        Width = 75
        Height = 19
        Anchors = [akTop, akRight]
        Caption = 'OT inversa'
        TabOrder = 9
        OnClick = Button23Click
      end
      object Button24: TButton
        Left = 157
        Top = 19
        Width = 183
        Height = 25
        Caption = 'Replan'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 10
        OnClick = Button24Click
      end
      object btnResaltarOF: TcxButton
        Left = 346
        Top = 6
        Width = 66
        Height = 19
        Anchors = [akTop, akRight]
        Caption = 'RESALTAR OF'
        SpeedButtonOptions.GroupIndex = 2
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.AllowAllUp = True
        TabOrder = 11
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnResaltarOFClick
      end
      object btnResaltarOT: TcxButton
        Tag = 1
        Left = 346
        Top = 26
        Width = 66
        Height = 19
        Anchors = [akTop, akRight]
        Caption = 'RESALTAR OT'
        SpeedButtonOptions.GroupIndex = 1
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.AllowAllUp = True
        TabOrder = 12
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnResaltarOFClick
      end
    end
    object pnlTitulo: TPanel
      Left = 0
      Top = 0
      Width = 1130
      Height = 70
      Align = alTop
      BevelOuter = bvNone
      Color = 6313290
      ParentBackground = False
      TabOrder = 2
      object lblTitulo: TLabel
        Left = 69
        Top = 5
        Width = 122
        Height = 32
        Caption = 'Vista Gantt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        OnClick = lblTituloClick
      end
      object lblSubtitulo: TLabel
        Left = 69
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
        Left = 223
        Top = 31
        Width = 240
        Height = 29
        Alignment = taRightJustify
        AutoSize = False
        Caption = '01.01.2026  -  31.12.2026'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Segoe UI Semilight'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object Image1: TImage
        Left = 592
        Top = 7
        Width = 16
        Height = 16
        AutoSize = True
        Picture.Data = {
          0D546478536D617274496D61676589504E470D0A1A0A0000000D494844520000
          00100000001008060000001FF3FF610000001974455874536F66747761726500
          41646F626520496D616765526561647971C9653C0000000D744558745469746C
          650046696C7465723B851A65D10000004D49444154785EE5CCB10D00200C0341
          CFCC06D98D795821342E100299285051B8F31FDC3DB57B40ABC5237B025800B0
          157084F083354044C50A20B28F3540648EA30006009F039600180B20B50E0C1F
          BDB00076F6BE0000000049454E44AE426082}
        Visible = False
      end
      object Image2: TImage
        Left = 614
        Top = 7
        Width = 16
        Height = 16
        AutoSize = True
        Picture.Data = {
          0D546478536D617274496D61676589504E470D0A1A0A0000000D494844520000
          00100000001008060000001FF3FF610000001974455874536F66747761726500
          41646F626520496D616765526561647971C9653C0000002D744558745469746C
          6500436C6561722046696C7465723B46696C7465723B52656D6F76652046696C
          7465723B436C65617229F58C020000007B49444154785EB5D1C109C0200C0550
          77CA0ABD768A82037483ECD6213A455748B508C921FC44A487AF78F80F498A88
          2CE53B9EEB9499FC02F004C01E9045B8A5B88022B80C0145FC320210B22B9E07
          EC66CA32701F5B6D9116EAA57E8F77CD026242F69D056CC98630A07BF710C233
          18E5CC0FA244330803B7F002CE38AC29FE0CE78A0000000049454E44AE426082}
        Visible = False
      end
      object btnFocus: TButton
        Left = 511
        Top = 15
        Width = 75
        Height = 25
        Caption = 'btnFocus'
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
          4D313220335637483356334831325A4D31362031375632314833563137483136
          5A4D323220313056313448335631304832325A222F3E0D0A3C2F7376673E0D0A}
        Properties.FitMode = ifmProportionalStretch
        Properties.ReadOnly = True
        Properties.ShowFocusRect = False
        Style.BorderStyle = ebsNone
        TabOrder = 1
        Transparent = True
        Height = 52
        Width = 56
      end
      object btnGanttDates: TcxButton
        Left = 468
        Top = 37
        Width = 20
        Height = 19
        Caption = '...'
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        OptionsImage.Glyph.SourceHeight = 12
        OptionsImage.Glyph.SourceWidth = 12
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 2
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnGanttDatesClick
      end
      object pnlKPI3: TPanel
        AlignWithMargins = True
        Left = 1037
        Top = 5
        Width = 90
        Height = 60
        Margins.Left = 1
        Margins.Top = 5
        Margins.Bottom = 5
        Align = alRight
        BevelOuter = bvNone
        Color = 8308592
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 7041597
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 3
        object LblKPIValue3: TLabel
          Left = 0
          Top = 28
          Width = 90
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitTop = 16
        end
        object LblKPITitle3: TLabel
          Left = 0
          Top = 0
          Width = 90
          Height = 28
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'XXXXX'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          WordWrap = True
        end
      end
      object pnlKPI2: TPanel
        AlignWithMargins = True
        Left = 945
        Top = 5
        Width = 90
        Height = 60
        Margins.Left = 1
        Margins.Top = 5
        Margins.Right = 1
        Margins.Bottom = 5
        Align = alRight
        BevelOuter = bvNone
        Color = 5610465
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 7041597
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 4
        object LblKPIValue2: TLabel
          Left = 0
          Top = 28
          Width = 90
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitTop = 16
        end
        object LblKPITitle2: TLabel
          Left = 0
          Top = 0
          Width = 90
          Height = 28
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'XXXXX'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          WordWrap = True
        end
      end
      object pnlKPI1: TPanel
        AlignWithMargins = True
        Left = 853
        Top = 5
        Width = 90
        Height = 60
        Margins.Left = 1
        Margins.Top = 5
        Margins.Right = 1
        Margins.Bottom = 5
        Align = alRight
        BevelOuter = bvNone
        Color = 4803025
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 7041597
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 5
        object LblKPIValue1: TLabel
          Left = 0
          Top = 28
          Width = 90
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitTop = 16
        end
        object LblKPITitle1: TLabel
          Left = 0
          Top = 0
          Width = 90
          Height = 28
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Operarios sin asignar'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          WordWrap = True
        end
      end
      object pnlKPI0: TPanel
        AlignWithMargins = True
        Left = 761
        Top = 5
        Width = 90
        Height = 60
        Margins.Left = 1
        Margins.Top = 5
        Margins.Right = 1
        Margins.Bottom = 5
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 8220514
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 6
        object LblKPITitle0: TLabel
          Left = 0
          Top = 0
          Width = 90
          Height = 28
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Nodos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          WordWrap = True
        end
        object LblKPIValue0: TLabel
          Left = 0
          Top = 28
          Width = 90
          Height = 24
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '23 / 456'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitTop = 16
        end
      end
      object pnlKPIAlertas: TPanel
        AlignWithMargins = True
        Left = 664
        Top = 5
        Width = 80
        Height = 60
        Margins.Left = 1
        Margins.Top = 5
        Margins.Right = 16
        Margins.Bottom = 5
        Align = alRight
        BevelOuter = bvNone
        Color = 4803025
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 8220514
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 7
        OnClick = pnlKPIAlertasClick
        object Label8: TLabel
          Left = 0
          Top = 16
          Width = 80
          Height = 16
          Cursor = crHandPoint
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Salud del Plan'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          WordWrap = True
          OnClick = pnlKPIAlertasClick
          ExplicitTop = 0
        end
        object Label9: TLabel
          Left = 0
          Top = 32
          Width = 80
          Height = 24
          Cursor = crHandPoint
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '13'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = pnlKPIAlertasClick
          ExplicitTop = 16
          ExplicitWidth = 90
        end
        object Image3: TImage
          Left = 8
          Top = 35
          Width = 16
          Height = 16
          Cursor = crHandPoint
          Center = True
          Picture.Data = {
            0D546478536D617274496D61676589504E470D0A1A0A0000000D494844520000
            00100000001008060000001FF3FF610000001974455874536F66747761726500
            41646F626520496D616765526561647971C9653C0000000B744558745469746C
            6500496E666F3B6D122D860000007949444154785EA5D3DD09C0200C046047C9
            203E673A9DA2C3649D8003D8132214C1167BC2F7A086C3DF94735E295430F060
            31A66BFDB32350A041DF6851236B80C015459FA2569E0105FAA1320374B76CB4
            34BC6C47531C4E3F0D08754C1A116063D28900E703E6167E32FA10E96B241F12
            FF94F9CF447FE71B64B98D4C2A6C055E0000000049454E44AE426082}
          Proportional = True
          Stretch = True
          OnClick = pnlKPIAlertasClick
        end
        object Label10: TLabel
          Left = 0
          Top = 0
          Width = 80
          Height = 16
          Cursor = crHandPoint
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'ALERTAS'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
          OnClick = pnlKPIAlertasClick
          ExplicitTop = 8
        end
      end
    end
    object pnlSubTitulo: TPanel
      Left = 0
      Top = 70
      Width = 1130
      Height = 48
      Align = alTop
      BevelOuter = bvNone
      Color = 9404016
      ParentBackground = False
      TabOrder = 3
      DesignSize = (
        1130
        48)
      object Label20: TLabel
        Left = 360
        Top = 6
        Width = 74
        Height = 12
        Caption = 'Navegaci'#243'n nodos'
        Color = 12629935
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4800824
        Font.Height = -9
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentColor = False
        ParentFont = False
      end
      object Label21: TLabel
        Left = 181
        Top = 7
        Width = 37
        Height = 12
        Caption = 'Ir a fecha'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4800824
        Font.Height = -9
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object Label6: TLabel
        Left = 24
        Top = 7
        Width = 48
        Height = 12
        Caption = 'Vistas Gantt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4800824
        Font.Height = -9
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object Button27: TButton
        Tag = 1
        Left = 481
        Top = 6
        Width = 44
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Debug'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = Button27Click
      end
      object cbVistas: TcxComboBox
        Left = 24
        Top = 21
        ParentFont = False
        Properties.DropDownListStyle = lsFixedList
        Properties.DropDownRows = 20
        Properties.Items.Strings = (
          'gvmNormal'
          'gvmOptimitzacio'
          'gvmFabricacio'
          'gvmFechaEntrega'
          'gvmStock'
          'gvmOperarios   '
          'gvmCarga'
          'gvmEstado'
          'gvmPrioridad'
          'gvmRendimiento'
          'gvmColores'
          'gvmModificaciones')
        Properties.OnChange = cbVistasPropertiesChange
        Style.BorderColor = 3553567
        Style.BorderStyle = ebsSingle
        Style.Color = 8220514
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = []
        Style.HotTrack = False
        Style.LookAndFeel.NativeStyle = False
        Style.TextColor = clWhite
        Style.ButtonStyle = btsSimple
        Style.ButtonTransparency = ebtAlways
        Style.IsFontAssigned = True
        StyleDisabled.LookAndFeel.NativeStyle = False
        StyleFocused.LookAndFeel.NativeStyle = False
        StyleHot.LookAndFeel.NativeStyle = False
        StyleReadOnly.LookAndFeel.NativeStyle = False
        TabOrder = 1
        Text = 'gvmNormal'
        Width = 147
      end
      object cxDateEdit1: TcxDateEdit
        Left = 178
        Top = 21
        ParentFont = False
        Properties.ImmediatePost = True
        Properties.ShowTime = False
        Style.BorderColor = 3553567
        Style.BorderStyle = ebsSingle
        Style.Color = 8220514
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = []
        Style.LookAndFeel.NativeStyle = False
        Style.TextColor = clWhite
        Style.ButtonStyle = btsSimple
        Style.ButtonTransparency = ebtAlways
        Style.IsFontAssigned = True
        StyleDisabled.LookAndFeel.NativeStyle = False
        StyleFocused.LookAndFeel.NativeStyle = False
        StyleHot.LookAndFeel.NativeStyle = False
        StyleReadOnly.LookAndFeel.NativeStyle = False
        TabOrder = 2
        Width = 103
      end
      object btnIr: TcxButton
        Left = 283
        Top = 22
        Width = 29
        Height = 19
        Caption = 'Ir'
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 3
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnIrClick
      end
      object btnHoy: TcxButton
        Left = 313
        Top = 22
        Width = 35
        Height = 19
        Caption = 'Hoy'
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 4
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnHoyClick
      end
      object btnNodeGoToLast: TcxButton
        Left = 425
        Top = 22
        Width = 20
        Height = 19
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 12
        OptionsImage.Glyph.SourceWidth = 12
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000002A744558745469746C65004C6173743B4172726F773B466F72776172
          643B536B69703B4E6578743B526577696E643B5B449245000002934944415478
          5EA5935B48555D10C767EB399AA961178D34CE8B45F8701E7D2814CACA820A7A
          AAB07CA80CC98C0A310C4384B0A8C0822C8C48EA80DD03C920132F64A99C13A2
          562A1C022D341F3C712CB57D599769D66EE9F7E1AB1B8659336BE6B7FEB358DB
          404458CAE751CEA08F5CACCEC992FA01293882400152227086208504EEE6A4BB
          7E5195F38FA01578CF0786B0B82ED47EE0E2B32D14C791C51CAD0D41E1B52014
          5CE98583353DEE59641EBDEF75630D882F7BF01987C767B1FAF1081EB9DCD1B8
          F3445DD63CA87F8A4170D2720FAA080C7415DFEAC3A2DA9E2E17A401CBCEDE1F
          C4A88338FA1BB1E5D34F2CADEBB7F65F7873C7BFB364BD0619AAAEF2D110466D
          C4E33743AA312146CF6D7021C06208C3510989A9295074C81FBF2FDF7F322BB7
          6028EFD4D3CAD40D9B572B90BA9BEE71073897A0D479E6018201581261C61230
          3D479B845EEB5B03C70EAF5AD1FD31B5CABBBCBA68EAFBC80D468D8CEA045B04
          501B730E82C904086980C3054428A724666665802F332DBDB73BED3AA3BC2324
          384CB87DFF0128316B23FC21B292E948A042044E8B191B002D06B3A60D711E2F
          D8046142BA80853BB02D0ED3247F8E4C414C9B8394125030180C7E85E70F3B26
          42ADCDE596C941A9E56C1140C9FA4500D396A0D450278407C6E055E3BB99BEB6
          CE4BE196EAECB1CE9A80693B341E02D70A3C0B0022462D3709DFC293F0251876
          223FC6029191E6ABD3A3ED1394B6C9924D4B2B20C8FF5F624A7E791B963D19C5
          9C92D7B871CFEDA6347F6136E513F513372A5A23A0E26DA79BDE6F3FD78AB9C5
          2F3F509C340F48DE7AE62D6EDA5BDFBB2EBB74B78AF593357CF90D90B1E31EA4
          E7DD050D4B225BA97DACA10086E18E92A0C7B1C8B86F57034A2900258224A3C0
          F552485775A4A7D42D5EF2EFFC17EABC8B701AFC8B800000000049454E44AE42
          6082}
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 5
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnNodeGoToLastClick
      end
      object btnNodeGoToNext: TcxButton
        Left = 403
        Top = 22
        Width = 20
        Height = 19
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 12
        OptionsImage.Glyph.SourceWidth = 12
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001B744558745469746C65004E6578743B506C61793B4172726F773B52
          6967687416E40EAE000002AF49444154785EA5925D6895751CC73FCFD14D46BE
          B41AF6C20A870425152C2F82A08B0ABD295D05416F572184045D2644082A425A
          831A62128E2E448C59108D9430D84A1C81DBD4D6B6D05C3B739B5B3BB1EDAC73
          CEF33CFFDF4BCFE1807076DB173E7CF95FFC3E7C2FFE91BB136501D600D556C0
          3F3839EC8262062A86A9A3E2881B224AE9DF949E032F90A396B5877A46C3BEAF
          0687DF3DDABB0B683CBAE7A99C064352458212AA484053218943F55D3BA4969C
          A8B2E7C5C71E3FF7EBFAEFDEEBFAA56FE1D6C4FECFF73E7D1908638BC1821A6A
          10D439DCD58FA8D7092255A3A5B9898EE71F213FBBF9B99F06365D7CFBE0F9AF
          676E0C1FDED6DC70030803B3154B122388616AF582204A2A30B562DCD5BC8137
          3AB6716DEC9ED7FBD76F7C75C3E6B3DD7F0EF67EFCCC834D7380EC78BFD7D457
          2D90E0A46A9412A5583688E081875A78B3F5DEC6CBD75AF636346D7AAB65EBB3
          9DBF5F387EE242D7AE2520D0E59EBBB320552AC1A8A4423938C58A905F4C3302
          AD5BEE67F72BDB373EB1BDFDC0932F7D34D4FE5AE73B4063DD822408A5D4AB20
          6224197195580966AC6B8878B47D0B0F6FBDAFB5E754F205701A48EE082AA540
          A124148A29E6206A04ABC9725184C6C6D0C84D4606AF2FAE14663E03A47E811A
          CB15214E0D7343CC897211EBD6464C8C4F73F5D278BCFCF7ADEEF93F7A3B97A7
          06E680A44E90A6CA526CC4C18822674D2EC7FCC43C570646AD3033F5CD3F13FD
          870AD7CFFD05C480B5ED3CEEAB048195B262EE141796B87A7194DBF97CDFCAF4
          9583B77F3B35045400FDF0C7593F7DE45B4484D50B982B14B3C33126C76F8E94
          1646F74F0F7ED9079401D9F7C3AC03A880AA60AB7EA2A6B1F27DF7F9A9CAE2E4
          91C94B9F9C014A4068DB71CCCD9C339F9EA5DAA686BB634E9DA0FCF38997EFA6
          961848DB761E7337C7CC5071DC0C73C7AB4419A60044EECEFFC97FFDEAC21326
          FC988F0000000049454E44AE426082}
        OptionsImage.Layout = blGlyphBottom
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 6
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnNodeGoToNextClick
      end
      object btnNodeGoToFirst: TcxButton
        Left = 359
        Top = 22
        Width = 20
        Height = 19
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 12
        OptionsImage.Glyph.SourceWidth = 12
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          6100000027744558745469746C650046697273743B4172726F773B4261636B3B
          536B69703B507265763B526577696E64018E90D40000028D49444154785EA593
          5D4854411886DFB3EB6A922D68B56A7A91413F9219FE643FB089149178515090
          46175996601A097B51E84D52E14D255414265EA8650666D4452246B5EA86FDB0
          B63726041586441892BA1ECF9C99F99AB37BA4F6DA81E19DF9CE3B0FEF7798D1
          8808CB1971B6A2B1E73338279004040842484889A80AA994D05A9BEFB0CF58CA
          882C37A0D9C578002E6B7FA13D84DAFB9F50736F0CD5B783B00F2494D6B5EDAD
          B8F2FA55F9D5B704207129BDEB62C798BFFAD647AABA11F05BA05F3A615A4D1B
          1EBFFFF4F5ADC79A06BB7D6D217A1E9AA1A34D430460151145E2389D712E6FF3
          D9EDF0DD7DEFB5F69E442D92AAE850BD272BAFB4213575EDA9E21D99099E3437
          4C09306EC3EDE89AE084911F0C9C4B580936141C5C915F76AE363925CD575C98
          E9CEDEB406537302A19F1CEBDC0E7043C4001C26978A4C100A5F7ABEB5327D7D
          AEAF30273DA328271D61A961FCB7C0AC2EA00B826E28AF90B1094C2EC0549199
          02DEDD3B6FEED9B51170C5E1EBBCC4AC0118AACE149C73C202772815B100C624
          0C2E22E43F6143C5E5E04E07E60D012E084C024CA9A9206153A9F12F81C35A2C
          EA1C561B5C195EBE18A8EFE80C4C8E06BE80192CD29A6EF0680A2EB0C8A06A22
          16A02B23E3042E243EF436768F3EBA541818F45FEEEB1A991B0F7E8314028A0F
          9380059383F35800F4453B012700603393C1E9604F4DF3F8E09DBC40FF9BB6FE
          07C36C72620A2401836BE0CC6EC11E2B4BEA9E0EEDAB1F206F75EF3080A46BFE
          992583D3FAEEC93D5E9475A0E55941651F9D6C9FA09C8A3E02E02152629B9200
          24DBEADC56FE10D947BAB0E570E7FF57DDBD3AF74C594649CBBBCDE54F08408A
          05D0962879271E8338457F9088B623A504915AABFDF7FE2ACD7E2B8936344C44
          E6B29FF35F8A7E791DC98C55400000000049454E44AE426082}
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 7
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnNodeGoToFirstClick
      end
      object btnNodeGoToPrev: TcxButton
        Left = 381
        Top = 22
        Width = 20
        Height = 19
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 12
        OptionsImage.Glyph.SourceWidth = 12
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          6100000021744558745469746C6500507265763B4172726F773B4C6566743B42
          61636B3B526577696E640B2B870F000002AF49444154785EA5925D48544114C7
          FF773F52B30DD3DD75AF461BB56AA8E507A91946904451085A1651481F4A1624
          8118B818140616F4854FA1840F5191652941D683681019293D44190422852686
          0865EDAE7BE7CE4C33B39BA43E3670983367E6FCCE7FCE8C76A57B048C039C5B
          60320646394C938372E133310BFF7A759E06C002C08EC83038E70C32C818C029
          404C0642180C932910256236984C9689B1071AEF55545F7DF5AEFADA6048AE11
          1D36599181A3AE221306D3204B71007AAC45552CAFBF5D9498EC6BF67A5DDB4B
          F253D0F1F8A3CA9B07989C8333064D5D83438FB34A867DCFA91B696E6FCEF9D4
          14D7A1E23C1D4EA7039A0610CAF0EFB05111E08C23314625DA4A2AEBDDBEFC5D
          7E97CB5953B0498FF1AD73E247C8C4C44F0309715698730AA0CD032E1DCE910B
          6B7AC16E4761D9E9DA5549BABF60A3BE327B830B220F53B304813045D86408DB
          3418E622804CAEB9FCB4CA1AEFBC98ED4B5E939BE911112BA6030C41126D2C65
          0A103434988C2E01D8E313F48E7D3BD3118205D373F2208149014DE3601CC217
          200A04380531962AA053E35FFDED9DBF1B32D23C4919191E980C02C2401907A5
          5C2A5090B0DD02932C546001403A5B2A6FBEE969CD7D3930D4FAE0E1F0DCE8E7
          EFB0691CC48C48374CE903217925C617020E5EE89311636CB867B2FFD651FFFB
          BE3BF97DBDAF3BBBBB86D8E4F80CC0231F8B080B130EBAA889286B7C81BDE77A
          D13634FD976C05B062EDD6DA92DCFDED033BCEF6F2BABB9F78D3F309659B8FF5
          70006ECE39A4D9C201A2E8B3418696FE2919A34DA59EC097C1B6B700CA576F39
          53FA6D2CAB3975BD372BABD007932D54A06D3BF9049432D51CCA289894C9217C
          8691AE2A4BB4D18ED4A286237687B7DEE1D6BD1FEE573A45A51905283EFE084C
          DE316CCAAE4B5F01B8F223771E7D7642829601588EC8F8250044018483FF197F
          0048B183E0A83E959B0000000049454E44AE426082}
        OptionsImage.Layout = blGlyphBottom
        PaintStyle = bpsGlyph
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 8
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnNodeGoToPrevClick
      end
      object btnShowWeekends: TcxButton
        Left = 455
        Top = 22
        Width = 20
        Height = 19
        Hint = 'Ver fines de semana'
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C00000013744558745469746C650046756C6C5765656B56696577
          3BD537A9CC000001BC49444154785E8D93B16A15511086FFBD77B110D3F81656
          363616499546D04241F429D4C2C6CAE6464B4B9F20014B4340041134828A8549
          29F80ADAA8D7B03B33BF3367861CD0C6657FBED93967E69F3D700600A36B81FE
          0CC5AE7FD7E832970C6F6F5E7BB304B6CC0C6644902E75451C8F697E33A8B96F
          1239BCFDE1D3F6380ED8BA70FD0AC02C8629A0848980AAE9E75451C065127B04
          EFF75F6D02588E46B68D275FBFA46338B82247AD092A0E45BC3CB701327F69A4
          11364DD070941C9FA2C5FE0B0C59E567272D1B1CDF58E1F2AD8BD83002F10E68
          84936553CAC5217307CF8E808F97868594CBDEC1318CC4DEFE512BDC7DFE1961
          B2EBDFC1EF8FEEB5F56F3B776146CCB30240341027A1AA30A29DB6929D9AB422
          8BD5008B79B62C548255608622A1E2AC8336252C6880D7E504B308C072EA8549
          0262EA31A2414E2056BF20D560521080B406AE1A5124991374675A36EA0D3C20
          C2596BE4603634E5E9445416238F7E06D3DC0ABBB3311D2D9DB511603542E5A5
          CE60B8F3F0051F3FD8C6CFB5822D4564E028267A3EB07AF21A4F77AE9E1FD7EB
          1F87F7572F3741827D7715F4CBC7861E4F27BFDE0562C759D799BFAEF1F01FD7
          7972FDFE035F8CEE42D0F2A8C60000000049454E44AE426082}
        ParentShowHint = False
        ShowHint = True
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 9
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnShowWeekendsClick
      end
      object pnlOperarios: TPanel
        Left = 630
        Top = 0
        Width = 500
        Height = 48
        Align = alRight
        BevelOuter = bvNone
        Color = 9404016
        ParentBackground = False
        TabOrder = 10
        object Label23: TLabel
          Left = 24
          Top = 6
          Width = 39
          Height = 12
          Caption = 'Operarios'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4800824
          Font.Height = -9
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object Shape3: TShape
          Left = 0
          Top = 0
          Width = 1
          Height = 48
          Align = alLeft
          Brush.Color = 6313290
          Pen.Color = 6313290
          ExplicitHeight = 500
        end
        object Label19: TLabel
          Left = 191
          Top = 6
          Width = 62
          Height = 12
          Caption = 'Departamentos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4800824
          Font.Height = -9
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object btnHighlightOperarios: TcxButton
          Left = 379
          Top = 21
          Width = 21
          Height = 19
          Hint = 'Resaltar operarios'
          Colors.PressedText = 7136979
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Sharp'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 14
          OptionsImage.Glyph.SourceWidth = 14
          OptionsImage.Glyph.Data = {
            89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
            610000003F744558745469746C6500436F6E646974696F6E616C466F726D6174
            74696E7349636F6E5365745374617273333B436F6E646974696F6E616C466F72
            6D617474696E673BBD1216EC0000032C49444154785E45926D485B571CC69F73
            131793D4248B26EB5A496A8BA26E6E3ACA46192BD889C3B1C98476AC30F61206
            5DCBFAA576C240987BB5DD8B1F4A999B038BF8C142EBC656B73A669DB8B56C85
            958C2AAD7496D48A1A6B6362D47B73EF3DE7BF136F322F3C3CFC9F737FCFE1DE
            73D8A5F6DD2002400C04211DB999D078F21A1B7EF709CA06042BA3FFD7AD9951
            6606F9C74AD986334758193A56DBF94257F43DCAC4C42605E477196A6B817D33
            DC5C60853BD8E0D1C75EF604C36DE70E9B51E6D87196D45B395AE41082E0801D
            C437E19C1F7DB6D4E9F5074E3EF97A2BFEE8FEE044E4E9FB3F9230D798458248
            582E28574016CC5C150C8072EED0A36F57EC6B09398C1B28AF7F29D4383F7F48
            71579D02C0A520D251923404B73845CADEDA18F2F447AAF70DBCF548EBD8A7CD
            29BEF0039993ED64CE7D47A31FBD98EA7FA3F278CFC1F286C89EAD3E00055236
            29C6060FD77C52E42F39E82BDD59E67D3804EFF630BC8107615BFD1330328062
            87B9E529A41613589E8D2139378344EC762CB9B434F06AFF54BB32757BF94CE2
            5EDA5D59DF805DB5611417DD83B27C05B49E86D033202D2DE7DF651EC7AEC7B7
            A1AA7E2F12F7D3EE7FA697FBACC307948E866D7555655B479E3F72C057A0CF02
            DCB07E14114848877428306C0FE1A79EA164F456FCB9CFAF2CFEFD55532957CC
            A571D1313217BD39BDD03CFCCDF9355D2996BC019E5121A44857C1750D06F361
            B8F7E2DAC4BF8BFB257C4DBFFB3DE73C5BCB3598F15FF8FBA373575753A90175
            651D649A12CC6C80C2D0C0B88096D6B0924C9FEDBC1CBFACDF19304972C57E27
            14E23A84A9C3FA1E1674BA0B21D415803128853E10D9C0D5340ADD0FC0060401
            10991A88AB1082A06407C80190EF3B9D6185A7C0DC01C4664C8C5F9840ECAE09
            B8FCC8E6AE22E74E20C764952F209ED928F0F8BCA1C9BFA6F0ED17BF6ADD5D23
            BD17C7A79BBEEE1AEDEDE91AD726AF4EC3E5716F07F28C14017612D92681E66A
            BF33313BCF2EFC1CFFF266CA38FDDBBCB690BB7963CF248D8FE571BFB3B72618
            692AF73A21B43502411001EA8DD352A710D91D74BD56170800704829EAC46750
            AF9F90EACCDF56C72B35C5C137EB4A5CEBD10FB11EED405F4B19FE0365D3BD53
            AA437B1A0000000049454E44AE426082}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.GroupIndex = 1
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          TabOrder = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnFilterOperarios: TcxButton
          Left = 401
          Top = 21
          Width = 21
          Height = 19
          Hint = 'Filtrar operarios'
          Colors.PressedText = 7136979
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Sharp'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 14
          OptionsImage.Glyph.SourceWidth = 14
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
            63653D227072657365727665223E2E426C75657B66696C6C3A23313137374437
            3B7D262331333B262331303B2623393B2E59656C6C6F777B66696C6C3A234646
            423131353B7D262331333B262331303B2623393B2E426C61636B7B66696C6C3A
            233732373237323B7D262331333B262331303B2623393B2E477265656E7B6669
            6C6C3A233033394332333B7D262331333B262331303B2623393B2E5265647B66
            696C6C3A234431314331433B7D262331333B262331303B2623393B2E7374307B
            6F7061636974793A302E37353B7D262331333B262331303B2623393B2E737431
            7B6F7061636974793A302E353B7D3C2F7374796C653E0D0A3C672069643D2246
            696C746572223E0D0A09093C706F6C79676F6E20636C6173733D2259656C6C6F
            772220706F696E74733D22362C342032362C342032362C382031382C31362031
            382C32342031342C32382031342C313620362C38202623393B222F3E0D0A093C
            2F673E0D0A3C2F7376673E0D0A}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.GroupIndex = 1
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          TabOrder = 1
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FcxFilterOperarios: TcxCheckComboBox
          Left = 24
          Top = 20
          ParentFont = False
          Properties.DropDownRows = 30
          Properties.Items = <>
          Properties.OnChange = cbDepartamentosPropertiesChange
          Style.BorderColor = 3553567
          Style.BorderStyle = ebsSingle
          Style.Color = 8220514
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clWindowText
          Style.Font.Height = -11
          Style.Font.Name = 'Segoe UI'
          Style.Font.Style = []
          Style.LookAndFeel.NativeStyle = False
          Style.TextColor = clWhite
          Style.ButtonStyle = btsSimple
          Style.ButtonTransparency = ebtAlways
          Style.IsFontAssigned = True
          StyleDisabled.LookAndFeel.NativeStyle = False
          StyleFocused.LookAndFeel.NativeStyle = False
          StyleHot.LookAndFeel.NativeStyle = False
          StyleReadOnly.LookAndFeel.NativeStyle = False
          TabOrder = 2
          Width = 160
        end
        object cbDepartamentos: TcxCheckComboBox
          Left = 191
          Top = 20
          ParentFont = False
          Properties.DropDownRows = 30
          Properties.Items = <>
          Properties.OnChange = cbDepartamentosPropertiesChange
          Style.BorderColor = 3553567
          Style.BorderStyle = ebsSingle
          Style.Color = 8220514
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clWindowText
          Style.Font.Height = -11
          Style.Font.Name = 'Segoe UI'
          Style.Font.Style = []
          Style.LookAndFeel.NativeStyle = False
          Style.TextColor = clWhite
          Style.ButtonStyle = btsSimple
          Style.ButtonTransparency = ebtAlways
          Style.IsFontAssigned = True
          StyleDisabled.LookAndFeel.NativeStyle = False
          StyleFocused.LookAndFeel.NativeStyle = False
          StyleHot.LookAndFeel.NativeStyle = False
          StyleReadOnly.LookAndFeel.NativeStyle = False
          TabOrder = 3
          Width = 160
        end
        object btnClearOperarios: TcxButton
          Left = 357
          Top = 21
          Width = 21
          Height = 19
          Caption = 'X'
          Colors.PressedText = 7136979
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Sharp'
          OptionsImage.Glyph.SourceHeight = 12
          OptionsImage.Glyph.SourceWidth = 12
          SpeedButtonOptions.GroupIndex = 1
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          SpeedButtonOptions.Down = True
          TabOrder = 4
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnClearOperariosClick
        end
        object btnAutoPlanSel: TcxButton
          Left = 433
          Top = 21
          Width = 21
          Height = 19
          Hint = 'Auto asignar selecci'#243'n'
          Colors.PressedText = 7136979
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Sharp'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 14
          OptionsImage.Glyph.SourceWidth = 14
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
            63653D227072657365727665223E2E426C75657B66696C6C3A23313137374437
            3B7D262331333B262331303B2623393B2E59656C6C6F777B66696C6C3A234646
            423131353B7D262331333B262331303B2623393B2E5265647B66696C6C3A2344
            31314331433B7D262331333B262331303B2623393B2E477265656E7B66696C6C
            3A233033394332333B7D262331333B262331303B2623393B2E426C61636B7B66
            696C6C3A233732373237323B7D262331333B262331303B2623393B2E57686974
            657B66696C6C3A234646464646463B7D262331333B262331303B2623393B2E73
            74307B6F7061636974793A302E353B7D262331333B262331303B2623393B2E73
            74317B6F7061636974793A302E37353B7D262331333B262331303B2623393B2E
            7374327B646973706C61793A6E6F6E653B7D262331333B262331303B2623393B
            2E7374337B646973706C61793A696E6C696E653B66696C6C3A23464642313135
            3B7D262331333B262331303B2623393B2E7374347B646973706C61793A696E6C
            696E653B7D262331333B262331303B2623393B2E7374357B646973706C61793A
            696E6C696E653B6F7061636974793A302E37353B7D262331333B262331303B26
            23393B2E7374367B646973706C61793A696E6C696E653B6F7061636974793A30
            2E353B7D262331333B262331303B2623393B2E7374377B646973706C61793A69
            6E6C696E653B66696C6C3A233033394332333B7D262331333B262331303B2623
            393B2E7374387B646973706C61793A696E6C696E653B66696C6C3A2344313143
            31433B7D262331333B262331303B2623393B2E7374397B646973706C61793A69
            6E6C696E653B66696C6C3A233131373744373B7D262331333B262331303B2623
            393B2E737431307B646973706C61793A696E6C696E653B66696C6C3A23464646
            4646463B7D3C2F7374796C653E0D0A3C672069643D22506572736F6E223E0D0A
            09093C7061746820636C6173733D22477265656E2220643D224D31302C392E39
            632D302E312C302E352C302E322C302E392C302E342C312E34732D302E312C31
            2E372C302E392C312E3663302C302C302C302E312C302C302E3263302E362C32
            2E332C322C342E392C342E372C342E3973342E322D322E362C342E372D342E39
            20202623393B2623393B56313363312C302E312C302E362D312E312C302E392D
            312E3663302E322D302E352C302E342D302E392C302E332D312E34632D302E31
            2D302E342D302E342D302E342D302E352D302E334332332E322C342E382C3230
            2E332C352C32302E332C355332302C322C31342E382C3220202623393B262339
            3B4331302C322C392E342C362C31302E352C392E364331302E342C392E362C31
            302E312C392E372C31302C392E397A204D32302C3138632D302E382C312E352D
            322E312C342D342C34732D332E322D322E352D342D34632D322E332C332E352D
            382C312D382C382E35563330683234762D332E3520202623393B2623393B4332
            382C31392E312C32322E332C32312E342C32302C31387A222F3E0D0A093C2F67
            3E0D0A3C2F7376673E0D0A}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          TabOrder = 5
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnAutoPlanSelClick
        end
        object btnDesasignarSel: TcxButton
          Left = 455
          Top = 21
          Width = 21
          Height = 19
          Hint = 'Desasignar selecci'#243'n'
          Colors.PressedText = 7136979
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          LookAndFeel.SkinName = 'Sharp'
          OptionsImage.Glyph.SourceDPI = 96
          OptionsImage.Glyph.SourceHeight = 14
          OptionsImage.Glyph.SourceWidth = 14
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
            63653D227072657365727665223E2E426C61636B7B66696C6C3A233732373237
            323B7D262331333B262331303B2623393B2E59656C6C6F777B66696C6C3A2346
            46423131353B7D262331333B262331303B2623393B2E426C75657B66696C6C3A
            233131373744373B7D262331333B262331303B2623393B2E5265647B66696C6C
            3A234431314331433B7D262331333B262331303B2623393B2E57686974657B66
            696C6C3A234646464646463B7D262331333B262331303B2623393B2E47726565
            6E7B66696C6C3A233033394332333B7D262331333B262331303B2623393B2E73
            74307B66696C6C3A233732373237323B7D262331333B262331303B2623393B2E
            7374317B6F7061636974793A302E353B7D262331333B262331303B2623393B2E
            7374327B6F7061636974793A302E37353B7D3C2F7374796C653E0D0A3C672069
            643D225061796D656E74556E70616964223E0D0A09093C7061746820636C6173
            733D225265642220643D224D31362C3243382E322C322C322C382E322C322C31
            3673362E322C31342C31342C31347331342D362E322C31342D31345332332E38
            2C322C31362C327A204D31362C3663322C302C342C302E362C352E362C312E36
            4C372E382C32312E3420202623393B2623393B43362E362C32302C362C31382C
            362C313643362C31302E342C31302E342C362C31362C367A204D31362C323663
            2D322C302D342D302E362D352E362D312E366C31332E382D31332E384332352E
            342C31322C32362C31342C32362C31364332362C32312E362C32312E362C3236
            2C31362C32367A222F3E0D0A093C2F673E0D0A3C2F7376673E0D0A}
          ParentShowHint = False
          ShowHint = True
          SpeedButtonOptions.CanBeFocused = False
          SpeedButtonOptions.AllowAllUp = True
          TabOrder = 6
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnDesasignarSelClick
        end
      end
    end
  end
  object popCentros: TPopupMenu
    Left = 896
    Top = 364
    object INFO3: TMenuItem
      Caption = 'Propiedades...'
      OnClick = INFO3Click
    end
    object Indicadores1: TMenuItem
      Caption = 'Indicadores...'
      OnClick = Indicadores1Click
    end
  end
  object popGantt: TPopupMenu
    Left = 984
    Top = 364
    object miSeleccion: TMenuItem
      Caption = 'Selecci'#243'n'
      object miSelDia: TMenuItem
        Caption = 'D'#237'a: seleccionar todo'
        OnClick = miSelDiaClick
      end
      object miSelSemana: TMenuItem
        Caption = 'Semana: seleccionar todo'
        OnClick = miSelSemanaClick
      end
      object miSelDeseleccionar: TMenuItem
        Caption = 'Deseleccionar todo'
        OnClick = miSelDeseleccionarClick
      end
    end
    object N5: TMenuItem
      Caption = '-'
    end
    object MenuItem1: TMenuItem
      Caption = 'Asignar fecha bloqueo'
      OnClick = MenuItem1Click
    end
    object Desactivarfechabloqueo1: TMenuItem
      Caption = 'Desactivar fecha bloqueo'
      OnClick = Desactivarfechabloqueo1Click
    end
    object Calendario1: TMenuItem
      Caption = 'Calendario info...'
      OnClick = Calendario1Click
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object ShiftRow1: TMenuItem
      Caption = 'Shift all Rows'
      OnClick = ShiftRow1Click
    end
    object ShiftRowallimpact1: TMenuItem
      Caption = 'Shift Row all impact'
      OnClick = ShiftRowallimpact1Click
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object Aadirmarcador1: TMenuItem
      Caption = 'A'#241'adir marcador...'
      OnClick = Aadirmarcador1Click
    end
    object Gestionmarcadores1: TMenuItem
      Caption = 'Gesti'#243'n de marcadores...'
      OnClick = Gestionmarcadores1Click
    end
    object Marcadoresautomaticos1: TMenuItem
      AutoCheck = True
      Caption = 'Marcadores autom'#225'ticos (Entrega/Necesaria)'
      OnClick = Marcadoresautomaticos1Click
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object RestaurarVistaDefecto1: TMenuItem
      Caption = 'Restaurar vista por defecto'
      OnClick = RestaurarVistaDefecto1Click
    end
  end
  object popTimeline: TPopupMenu
    Left = 896
    Top = 308
    object MenuItem2: TMenuItem
      Caption = 'PopTimeline'
    end
  end
  object popNode: TPopupMenu
    OnPopup = popNodePopup
    Left = 984
    Top = 308
    object MenuItem3: TMenuItem
      AutoCheck = True
      Caption = 'Bloqueado'
      OnClick = MenuItem3Click
    end
    object LibreMovimiento1: TMenuItem
      AutoCheck = True
      Caption = 'Libre Movimiento'
      OnClick = LibreMovimiento1Click
    end
    object Resetduracinoriginal1: TMenuItem
      Caption = 'Restablecer duraci'#243'n original'
      OnClick = Resetduracinoriginal1Click
    end
    object CompactarOF1: TMenuItem
      Caption = 'Compactar OF'
      object odalaOF1: TMenuItem
        Tag = 1
        Caption = 'Toda la OF'
        OnClick = odalaOF1Click
      end
      object odalaOF2: TMenuItem
        Tag = 1
        Caption = 'Toda la OF con prioridad'
        HelpContext = 1
        OnClick = odalaOF1Click
      end
      object CompactarOFapartirdelNodo1: TMenuItem
        Caption = 'A partir del Nodo'
        OnClick = odalaOF1Click
      end
      object ApartirdelNodoconprioridad1: TMenuItem
        Caption = 'A partir del Nodo con prioridad'
        HelpContext = 1
        OnClick = odalaOF1Click
      end
    end
    object CompactarOT1: TMenuItem
      Caption = 'Compactar OT'
      object otalaOT1: TMenuItem
        Tag = 1
        Caption = 'Toda la OT'
        OnClick = otalaOT1Click
      end
      object odalaOTconprioridad1: TMenuItem
        Tag = 1
        Caption = 'Toda la OT con prioridad'
        HelpContext = 1
        OnClick = otalaOT1Click
      end
      object ApartirdelNodo1: TMenuItem
        Caption = 'A partir del Nodo'
        OnClick = otalaOT1Click
      end
      object ApartirdelNodoconprioridad2: TMenuItem
        Caption = 'A partir del Nodo con prioridad'
        HelpContext = 1
        OnClick = otalaOT1Click
      end
    end
    object ShiftRow2: TMenuItem
      Caption = 'ShiftRow'
      OnClick = ShiftRow2Click
    end
    object NLote1: TMenuItem
      Caption = '-'
    end
    object AgruparEnLote1: TMenuItem
      Caption = 'Agrupar en lote'
      OnClick = AgruparEnLote1Click
    end
    object VerLote1: TMenuItem
      Caption = 'Ver lote...'
      OnClick = VerLote1Click
    end
    object DesagruparLote1: TMenuItem
      Caption = 'Desagrupar lote'
      OnClick = DesagruparLote1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Color1: TMenuItem
      Caption = 'Color'
      object Colordelnode1: TMenuItem
        Caption = 'Color del node...'
        OnClick = Colordelnode1Click
      end
      object ColordelaOrdendetrabajo1: TMenuItem
        Tag = 1
        Caption = 'Color de la Orden de trabajo...'
        OnClick = Colordelnode1Click
      end
      object ColordelaOrdendeFabricacin1: TMenuItem
        Tag = 2
        Caption = 'Color de la Orden de Fabricaci'#243'n'
        OnClick = Colordelnode1Click
      end
      object ColordelPedido1: TMenuItem
        Tag = -1
        Caption = 'Color del Pedido...'
        Enabled = False
      end
      object ColordelProyecto1: TMenuItem
        Tag = -1
        Caption = 'Color del Proyecto...'
        Enabled = False
      end
    end
    object ResaltarOF1: TMenuItem
      Caption = 'Resaltar OF'
      OnClick = ResaltarOF1Click
    end
    object Info1: TMenuItem
      Caption = 'Info'
    end
    object SepOperarios1: TMenuItem
      Caption = '-'
    end
    object miAsignarOperarios: TMenuItem
      Caption = 'Asignar Operarios...'
      OnClick = miAsignarOperariosClick
    end
    object miGestionOperarios: TMenuItem
      Caption = 'Gesti'#243'n Operarios y Departamentos...'
      OnClick = miGestionOperariosClick
    end
    object SepOperarios2: TMenuItem
      Caption = '-'
    end
    object miEditarLinks: TMenuItem
      Caption = 'Editar Links (Dependencias)...'
      OnClick = miEditarLinksClick
    end
    object SepDesplanificar1: TMenuItem
      Caption = '-'
    end
    object miDesplanificar: TMenuItem
      Caption = 'Desplanificar (quitar del plan)'
      OnClick = miDesplanificarClick
    end
  end
  object cxImageList1: TcxImageList
    SourceDPI = 96
    Height = 24
    Width = 24
    FormatVersion = 1
    Left = 552
    Top = 288
    Bitmap = {
      494C01010C001800040018001800FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000600000006000000001002000000000000090
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000102310C71A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF112611CF0000000000000000000000000000000004769BC706C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF047FA8CF00000000000000000000000000000000000000C70000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000CF00000000000000000000000000000000102310C71A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF112611CF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF00000000000000001A3A1AFF1A3A1AFF0000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF00000000000000001A3A1AFF1A3A1AFF0000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000006C1FFFF06C1FFFF06C1FFFF06C1FFFF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF0000000000000000000000FF000000FF000000FF000000FF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF00000000000000001A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF00000000000000001A3A1AFF1A3A1AFF0000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000001A3A1AFF1A3A1AFF000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000006C1FFFF06C1FFFF06C1FFFF06C1FFFF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF0000000000000000000000FF000000FF000000FF000000FF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF00000000000000001A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF00000000000000001A3A1AFF1A3A1AFF0000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000001A3A1AFF1A3A1AFF000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF0000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF00000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF0000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF0000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00001A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF00000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF0000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00001A3A1AFF1A3A1AFF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF0000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000000000000000000000000000001A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF000000000000000000000000000000000E200EBF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF102310C700000000000000000000000000000000036C8FBF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF03769BC700000000000000000000000000000000000000BF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000C7000000000000000000000000000000000E200EBF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF102310C700000000000000000000000000000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      00000000000000000000000000001A3A1AFF1A3A1AFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000090000005F000000B0000000E40000
      00FD000000FD000000E6000000B2000000620000000A00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000090308035F0D1C0DB0152F15E41A3A
      1AFD1A3A1AFD152F15E60D1C0DB2030803620000000A00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000059000000E5000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000E80000005E000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000003070359152F15E51A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF163016E80308035E000000000000
      000000000000000000000000000000000000000000000000000004769BC706C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF047FA8CF00000000000000000000000000000000000000C70000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000CF00000000000000000000000000000000000000000000
      00000000000300000097000000FF000000FF000000CC00000065000000220000
      0003000000020000002100000062000000C8000000FF000000FF0000009E0000
      0004000000000000000000000000000000000000000000000000000000000000
      000000000003091409971A3A1AFF1A3A1AFF112511CC04090465000100220000
      0003000000020001002103080362102310C81A3A1AFF1A3A1AFF0A160A9E0000
      000400000000000000000000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF00000000000000000000000000000000000000000000
      000000000096000000FF000000F6000000640000000100000000000000000000
      0000000000000000000000000000000000010000005E000000F4000000FF0000
      009E000000000000000000000000000000000000000000000000000000000000
      0000091409961A3A1AFF183618F6040804640000000100000000000000000000
      0000000000000000000000000000000000010308035E183518F41A3A1AFF0A16
      0A9E00000000000000000000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000000000
      0057000000FF000000F60000003E000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000038000000F40000
      00FF0000005E0000000000000000000000000000000000000000000000000306
      03571A3A1AFF183618F60103013E000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001020138183518F41A3A
      1AFF0308035E000000000000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000006C1FFFF06C1FFFF00000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF0000000000000000000000FF000000FF0000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000070000
      00E3000000FF0000006700000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000005E0000
      00FF000000E80000000A0000000000000000000000000000000000000007152E
      15E31A3A1AFF0409046700000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000308035E1A3A
      1AFF163016E80000000A0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000006C1FFFF06C1FFFF00000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF0000000000000000000000FF000000FF0000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0000000000FF000000FF000000000000000000000000000000000000005A0000
      00FF000000D00000000100000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000010000
      00C8000000FF00000062000000000000000000000000000000000307035A1A3A
      1AFF112711D00000000100000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000011023
      10C81A3A1AFF030803620000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000AA0000
      00FF0000006B0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0063000000FF000000B2000000000000000000000000000000000B190BAA1A3A
      1AFF040A046B0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000308
      03631A3A1AFF0D1C0DB20000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000DE0000
      00FF000000290000000000000000000000000000000000000000000000000000
      00FF000000FF000000FF000000FF000000FF000000FF00000000000000000000
      0021000000FF000000E600000000000000000000000000000000132C13DE1A3A
      1AFF000100290000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF00000000000000000001
      00211A3A1AFF152F15E60000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000006C1FFFF06C1FFFF00000000000000000000000006C1
      FFFF06C1FFFF00000000000000000000000006C1FFFF06C1FFFF000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF0000000000000000000000FF000000FF0000000000000000000000000000
      00FF000000FF000000000000000000000000000000FF000000FF000000000000
      0000000000FF000000FF00000000000000000000000000000000000000F60000
      00FF0000000A0000000000000000000000000000000000000000000000000000
      00FF000000FF000000FF000000FF000000FF000000FF00000000000000000000
      0003000000FF000000FD00000000000000000000000000000000183618F61A3A
      1AFF0000000A0000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF00000000000000000000
      00031A3A1AFF1A3A1AFD0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000006C1FFFF06C1FFFF00000000000000000000000006C1
      FFFF06C1FFFF00000000000000000000000006C1FFFF06C1FFFF000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF0000000000000000000000FF000000FF0000000000000000000000000000
      00FF000000FF000000000000000000000000000000FF000000FF000000000000
      0000000000FF000000FF00000000000000000000000000000000000000F50000
      00FF0000000B0000000000000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0003000000FF000000FD00000000000000000000000000000000183618F51A3A
      1AFF0000000B0000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000000
      00031A3A1AFF1A3A1AFD0000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000DC0000
      00FF0000002B0000000000000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0023000000FF000000E400000000000000000000000000000000132B13DC1A3A
      1AFF0001002B0000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000001
      00231A3A1AFF152F15E40000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000A80000
      00FF0000006D0000000000000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0065000000FF000000B0000000000000000000000000000000000B190BA81A3A
      1AFF050A056D0000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000409
      04651A3A1AFF0D1C0DB00000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF00000000000000000000000000000000000000570000
      00FF000000D30000000200000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000010000
      00CC000000FF0000005F00000000000000000000000000000000030603571A3A
      1AFF122812D30000000200000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000011125
      11CC1A3A1AFF0308035F0000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF00000000000000000000000000000000000000060000
      00E0000000FF0000006C00000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000640000
      00FF000000E5000000090000000000000000000000000000000000000006152D
      15E01A3A1AFF040A046C00000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000040804641A3A
      1AFF152F15E5000000090000000000000000000000000000000006C1FFFF06C1
      FFFF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000000000
      0051000000FF000000F800000045000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000003E000000F60000
      00FF000000590000000000000000000000000000000000000000000000000206
      02511A3A1AFF193719F801040145000000000000000000000000000000000000
      000000000000000000000000000000000000000000000103013E183618F61A3A
      1AFF03070359000000000000000000000000000000000000000006C1FFFF06C1
      FFFF00000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000000000
      00000000008F000000FF000000F80000006C0000000200000000000000000000
      00000000000000000000000000000000000100000067000000F6000000FF0000
      0097000000000000000000000000000000000000000000000000000000000000
      00000812088F1A3A1AFF193719F8040A046C0000000200000000000000000000
      00000000000000000000000000000000000104090467183618F61A3A1AFF0914
      099700000000000000000000000000000000000000000000000006C1FFFF06C1
      FFFF00000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000006C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000FF000000FF00000000000000000000000000000000000000000000
      0000000000020000008F000000FF000000FF000000D30000006D0000002A0000
      000B0000000A000000290000006A000000D0000000FF000000FF000000960000
      0003000000000000000000000000000000000000000000000000000000000000
      0000000000020812088F1A3A1AFF1A3A1AFF122812D3050A056D0001002A0000
      000B0000000A00010029040A046A112711D01A3A1AFF1A3A1AFF091409960000
      000300000000000000000000000000000000000000000000000006C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF00000000000000000000000000000000000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF00000000000000000000000000000000000000000000
      0000000000000000000000000051000000E0000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000E300000056000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000002060251152D15E01A3A1AFF1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF1A3A1AFF152E15E303060356000000000000
      0000000000000000000000000000000000000000000000000000036C8FBF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF03769BC700000000000000000000000000000000000000BF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000C700000000000000000000000000000000000000000000
      00000000000000000000000000000000000600000057000000A8000000DC0000
      00F5000000F5000000DE000000AA0000005A0000000700000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000006030603570B190BA8132B13DC1836
      18F5183618F5132C13DE0B190BAA0307035A0000000700000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      000000000000000000000000000006C1FFFF06C1FFFF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000FF000000FF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000009011A235F035C79B0059ACBE406BE
      FBFD06BEFBFD059DCFE6035E7CB2011C25620000000A00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000405260002021A000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000102170004
      0629000000000000000000000000000000000000000000000000000000000000
      0000000000260000001A00000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000170000
      0029000000000000000000000000000000000000000000000000000000000000
      0000000100260000001A00000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000170001
      0029000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000171E59059CCDE506C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF05A0D3E8011A225E000000000000
      0000000000000000000000000000000000000000000000000000000000000004
      0525059BCDE5058BB8D90002021A000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000102170486B0D405A0
      D3E8000406290000000000000000000000000000000000000000000000000000
      0025000000E5000000D90000001A000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000017000000D40000
      00E8000000290000000000000000000000000000000000000000000000000001
      0025152F15E5132A13D90000001A000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000017132813D41630
      16E8000100290000000000000000000000000000000000000000000000000000
      0000000000030243599706C1FFFF06C1FFFF047CA3CC011D2765000304220000
      00030000000200030421011C256204779DC806C1FFFF06C1FFFF0249629E0000
      0004000000000000000000000000000000000000000000000000000000000001
      01140480A9D006C1FFFF047AA1CB000000010000000000000000000000000000
      00000000000000000000000000000000000000000000037296C406C1FFFF0486
      B0D4000102170000000000000000000000000000000000000000000000000000
      0014000000D0000000FF000000CB000000010000000000000000000000000000
      00000000000000000000000000000000000000000000000000C4000000FF0000
      00D4000000170000000000000000000000000000000000000000000000000000
      0014112711D01A3A1AFF112511CB000000010000000000000000000000000000
      00000000000000000000000000000000000000000000102210C41A3A1AFF1328
      13D4000000170000000000000000000000000000000000000000000000000000
      00000242589606C1FFFF06B3EDF6011D27640000000100000000000000000000
      000000000000000000000000000000000001011A225E06B0E9F406C1FFFF0249
      629E000000000000000000000000000000000000000000000000000000000000
      000000010114037093C200090D3A000000000000000901273373047EA8CF06B9
      F5FA06BBF7FB0481ABD1012937770000000A0000000000080A34037296C40001
      0217000000000000000000000000000000000000000000000000000000000000
      000000000014000000C20000003A000000000000000900000073000000CF0000
      00FA000000FB000000D1000000770000000A0000000000000034000000C40000
      0017000000000000000000000000000000000000000000000000000000000000
      0000000000140F220FC20102013A0000000000000009050C0573112611CF1A38
      1AFA1A381AFB112711D1060C06770000000A0000000001020134102210C40000
      0017000000000000000000000000000000000000000000000000000000000016
      1D5706C1FFFF06B3EDF6000B0F3E000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000090C3806B0E9F406C1
      FFFF011A225E0000000000000000000000000000000000000000000000000000
      00000000000000000000000000000002031E0484AED306C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF058AB7D80003042200000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000001E000000D3000000FF000000FF0000
      00FF000000FF000000FF000000FF000000D80000002200000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000001E122812D31A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF132A13D80001002200000000000000000000
      0000000000000000000000000000000000000000000000000000000000070599
      CAE306C1FFFF011F296700000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000011A225E06C1
      FFFF05A0D3E80000000A00000000000000000000000000000000000000000000
      00000000000000000000000000080483ADD206C1FFFF0588B3D60011164C0000
      000800000008000F14490483ADD206C1FFFF058AB7D80000000A000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000008000000D2000000FF000000D60000004C0000
      00080000000800000049000000D2000000FF000000D80000000A000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000008122812D21A3A1AFF132813D60205024C0000
      00080000000802040249122812D21A3A1AFF132A13D80000000A000000000000
      000000000000000000000000000000000000000000000000000001171F5A06C1
      FFFF0480A9D00000000100000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000010477
      9DC806C1FFFF011C256200000000000000000000000000000000000000000000
      000000000000000000000124306F06C1FFFF0589B5D700000110000000000000
      000000000000000000000000000D0483ADD206C1FFFF01293777000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000006F000000FF000000D700000010000000000000
      000000000000000000000000000D000000D2000000FF00000077000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000050B056F1A3A1AFF132913D700000010000000000000
      000000000000000000000000000D122812D21A3A1AFF060D0677000000000000
      0000000000000000000000000000000000000000000000000000035671AA06C1
      FFFF01212C6B0000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000011C
      266306C1FFFF035E7CB200000000000000000000000000000000000000000000
      0000000000000000000004789EC906C1FFFF0013195100000000000000000000
      0000000000000000000000000000000F144906C1FFFF0483ADD2000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000C9000000FF0000005100000000000000000000
      000000000000000000000000000000000049000000FF000000D2000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000102410C91A3A1AFF0206025100000000000000000000
      0000000000000000000000000000020402491A3A1AFF122712D2000000000000
      00000000000000000000000000000000000000000000000000000592C1DE06C1
      FFFF0004062900000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF00000000000000000003
      042106C1FFFF059DCFE600000000000000000000000006C1FFFF06C1FFFF06C1
      FFFF000000000000000006AFE7F306C1FFFF0000000F00000000000000000000
      00000000000000000000000000000000000806C1FFFF06BBF7FB000000010000
      000006C1FFFF06C1FFFF06C1FFFF0000000000000000000000FF000000FF0000
      00FF0000000000000000000000F3000000FF0000000F00000000000000000000
      000000000000000000000000000000000008000000FF000000FB000000010000
      0000000000FF000000FF000000FF00000000000000001A3A1AFF1A3A1AFF1A3A
      1AFF0000000000000000183518F31A3A1AFF0000000F00000000000000000000
      0000000000000000000000000000000000081A3A1AFF193819FB000000010000
      00001A3A1AFF1A3A1AFF1A3A1AFF00000000000000000000000006B3EDF606C1
      FFFF0000000A00000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF00000000000000000000
      000306C1FFFF06BEFBFD00000000000000000000000006C1FFFF06C1FFFF06C1
      FFFF000000000000000006ADE5F206C1FFFF0000011100000000000000000000
      00000000000000000000000000000000000906C1FFFF06B9F5FA000000000000
      000006C1FFFF06C1FFFF06C1FFFF0000000000000000000000FF000000FF0000
      00FF0000000000000000000000F2000000FF0000001100000000000000000000
      000000000000000000000000000000000009000000FF000000FA000000000000
      0000000000FF000000FF000000FF00000000000000001A3A1AFF1A3A1AFF1A3A
      1AFF0000000000000000173417F21A3A1AFF0000001100000000000000000000
      0000000000000000000000000000000000091A3A1AFF193819FA000000000000
      00001A3A1AFF1A3A1AFF1A3A1AFF00000000000000000000000006B2EBF506C1
      FFFF0000000B00000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000000
      000306C1FFFF06BEFBFD00000000000000000000000000000000000000000000
      0000000000000000000003769BC706C1FFFF00151B5400000000000000000000
      00000000000000000000000000000010164C06C1FFFF047FA8CF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000C7000000FF0000005400000000000000000000
      00000000000000000000000000000000004C000000FF000000CF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000102310C71A3A1AFF0206025400000000000000000000
      00000000000000000000000000000205024C1A3A1AFF112611CF000000000000
      00000000000000000000000000000000000000000000000000000590BDDC06C1
      FFFF0005072B00000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000003
      042306C1FFFF059ACBE400000000000000000000000000000000000000000000
      0000000000000000000001212C6B06C1FFFF058EBCDB00010114000000000000
      00000000000000000000000001100588B3D606C1FFFF01273373000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000006B000000FF000000DB00000014000000000000
      0000000000000000000000000010000000D6000000FF00000073000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000040A046B1A3A1AFF132B13DB00000014000000000000
      0000000000000000000000000010132813D61A3A1AFF050C0573000000000000
      000000000000000000000000000000000000000000000000000003546EA806C1
      FFFF01222E6D00000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF000000000000000000000000000000000000000000000000011D
      276506C1FFFF035C79B000000000000000000000000000000000000000000000
      0000000000000000000000000006047EA6CE06C1FFFF058EBCDB00151B540000
      01100000000F001319510589B5D706C1FFFF0485B0D400000009000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000006000000CE000000FF000000DB000000540000
      00100000000F00000051000000D7000000FF000000D400000009000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000006112611CE1A3A1AFF132B13DB020602540000
      00100000000F02060251132913D71A3A1AFF122812D400000009000000000000
      000000000000000000000000000000000000000000000000000000161D5706C1
      FFFF0484AED300000002000000000000000000000000000000000000000006C1
      FFFF06C1FFFF000000000000000000000000000000000000000000000001047C
      A3CC06C1FFFF011A235F00000000000000000000000000000000000000000000
      00000000000000000001000000000002021A047DA4CD06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF0483ADD20002031E00000000000000010000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000001000000000000001A000000CD000000FF000000FF0000
      00FF000000FF000000FF000000FF000000D20000001E00000000000000010000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000001000000000000001A112611CD1A3A1AFF1A3A1AFF1A3A
      1AFF1A3A1AFF1A3A1AFF1A3A1AFF122812D20000001E00000000000000010000
      0000000000000000000000000000000000000000000000000000000000060595
      C4E006C1FFFF01222D6C000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000011D276406C1
      FFFF059CCDE50000000900000000000000000000000000000000000000000000
      00000001021704789EC9000B0F3F000000000000000601212C6B03759BC706AD
      E5F206AFE7F304789EC90124306F000000080000000000090D3A047AA1CB0002
      021A000000000000000000000000000000000000000000000000000000000000
      000000000017000000C90000003F00000000000000060000006B000000C70000
      00F2000000F3000000C90000006F00000008000000000000003A000000CB0000
      001A000000000000000000000000000000000000000000000000000000000000
      000000000017102410C90103013F0000000000000006040A046B102310C71834
      18F2183518F3102410C9050B056F00000008000000000102013A112511CB0000
      001A000000000000000000000000000000000000000000000000000000000013
      195106C1FFFF06B7F1F8000E1245000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000B0F3E06B3EDF606C1
      FFFF00171E590000000000000000000000000000000000000000000000000001
      02170486B0D406C1FFFF04789EC9000000010000000000000000000000000000
      00000000000000000000000000000000000000000000037093C206C1FFFF058B
      B8D90002021A0000000000000000000000000000000000000000000000000000
      0017000000D4000000FF000000C9000000010000000000000000000000000000
      00000000000000000000000000000000000000000000000000C2000000FF0000
      00D90000001A0000000000000000000000000000000000000000000000000000
      0017132813D41A3A1AFF102410C9000000010000000000000000000000000000
      000000000000000000000000000000000000000000000F220FC21A3A1AFF132A
      13D90000001A0000000000000000000000000000000000000000000000000000
      0000023C508F06C1FFFF06B7F1F801222D6C0000000200000000000000000000
      000000000000000000000000000000000001011F296706B3EDF606C1FFFF0243
      5997000000000000000000000000000000000000000000000000000000000003
      04220597C6E10486B0D400010217000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000101140480A9D0059B
      CDE5000405260000000000000000000000000000000000000000000000000000
      0022000000E1000000D400000017000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000014000000D00000
      00E5000000260000000000000000000000000000000000000000000000000001
      0022152D15E1132813D400000017000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000014112711D0152F
      15E5000100260000000000000000000000000000000000000000000000000000
      000000000002023C508F06C1FFFF06C1FFFF0484AED301222E6D0005062A0000
      000B0000000A0004062901212B6A0480A9D006C1FFFF06C1FFFF024258960000
      0003000000000000000000000000000000000000000000000000000000000000
      00000003042200010217000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000101140004
      0525000000000000000000000000000000000000000000000000000000000000
      0000000000220000001700000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000140000
      0025000000000000000000000000000000000000000000000000000000000000
      0000000100220000001700000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000140001
      0025000000000000000000000000000000000000000000000000000000000000
      00000000000000000000001319510595C4E006C1FFFF06C1FFFF06C1FFFF06C1
      FFFF06C1FFFF06C1FFFF06C1FFFF06C1FFFF0599CAE300151C56000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000600161D5703536EA80590BDDC06B2
      EBF506B2EBF50592C1DE035671AA01171F5A0000000700000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000006C1
      FFFF06C1FFFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00FF000000FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000001A3A
      1AFF1A3A1AFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000060000000600000000100010000000000800400000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000}
    DesignInfo = 18874920
    ImageInfo = <
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223464643313037223E0D0A093C7061746820643D224D
          31322031386136203620302031203120302D3132203620362030203020312030
          2031327A6D302D326134203420302031203020302D3820342034203020302030
          203020387A4D3131203168327633682D3256317A6D3020313968327633682D32
          762D337A4D332E35313520342E3932396C312E3431342D312E3431344C372E30
          3520352E36333620352E36333620372E303520332E35313520342E39337A4D31
          362E39352031382E3336346C312E3431342D312E34313420322E31323120322E
          3132312D312E34313420312E3431342D322E3132312D322E3132317A6D322E31
          32312D31342E38356C312E34313420312E3431352D322E31323120322E313231
          2D312E3431342D312E34313420322E3132312D322E3132317A4D352E36333620
          31362E39356C312E34313420312E3431342D322E31323120322E3132312D312E
          3431342D312E34313420322E3132312D322E3132317A4D32332031317632682D
          33762D3268337A4D3420313176324831762D3268337A222F3E0D0A3C2F737667
          3E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-dia-active.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223303030303030223E0D0A093C7061746820643D224D
          31322031386136203620302031203120302D3132203620362030203020312030
          2031327A6D302D326134203420302031203020302D3820342034203020302030
          203020387A4D3131203168327633682D3256317A6D3020313968327633682D32
          762D337A4D332E35313520342E3932396C312E3431342D312E3431344C372E30
          3520352E36333620352E36333620372E303520332E35313520342E39337A4D31
          362E39352031382E3336346C312E3431342D312E34313420322E31323120322E
          3132312D312E34313420312E3431342D322E3132312D322E3132317A6D322E31
          32312D31342E38356C312E34313420312E3431352D322E31323120322E313231
          2D312E3431342D312E34313420322E3132312D322E3132317A4D352E36333620
          31362E39356C312E34313420312E3431342D322E31323120322E3132312D312E
          3431342D312E34313420322E3132312D322E3132317A4D32332031317632682D
          33762D3268337A4D3420313176324831762D3268337A222F3E0D0A3C2F737667
          3E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-dia-black.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223314233423142223E0D0A093C7061746820643D224D
          31322031386136203620302031203120302D3132203620362030203020312030
          2031327A6D302D326134203420302031203020302D3820342034203020302030
          203020387A4D3131203168327633682D3256317A6D3020313968327633682D32
          762D337A4D332E35313520342E3932396C312E3431342D312E3431344C372E30
          3520352E36333620352E36333620372E303520332E35313520342E39337A4D31
          362E39352031382E3336346C312E3431342D312E34313420322E31323120322E
          3132312D312E34313420312E3431342D322E3132312D322E3132317A6D322E31
          32312D31342E38356C312E34313420312E3431352D322E31323120322E313231
          2D312E3431342D312E34313420322E3132312D322E3132317A4D352E36333620
          31362E39356C312E34313420312E3431342D322E31323120322E3132312D312E
          3431342D312E34313420322E3132312D322E3132317A4D32332031317632682D
          33762D3268337A4D3420313176324831762D3268337A222F3E0D0A3C2F737667
          3E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-dia-disabled.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223464643313037223E0D0A093C7061746820643D224D
          313220323243362E34373720323220322031372E353233203220313253362E34
          37372032203132203273313020342E3437372031302031302D342E3437372031
          302D31302031307A6D302D326138203820302031203020302D31362038203820
          302030203020302031367A6D312D3868347632682D365637683276357A222F3E
          0D0A3C2F7376673E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-hora-active.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223303030303030223E0D0A093C7061746820643D224D
          313220323243362E34373720323220322031372E353233203220313253362E34
          37372032203132203273313020342E3437372031302031302D342E3437372031
          302D31302031307A6D302D326138203820302031203020302D31362038203820
          302030203020302031367A6D312D3868347632682D365637683276357A222F3E
          0D0A3C2F7376673E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-hora-black.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223314233423142223E0D0A093C7061746820643D224D
          313220323243362E34373720323220322031372E353233203220313253362E34
          37372032203132203273313020342E3437372031302031302D342E3437372031
          302D31302031307A6D302D326138203820302031203020302D31362038203820
          302030203020302031367A6D312D3868347632682D365637683276357A222F3E
          0D0A3C2F7376673E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-hora-disabled.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223464643313037223E0D0A093C7061746820643D224D
          3137203368346131203120302030203120312031763136613120312030203020
          312D3120314833613120312030203020312D312D315634613120312030203020
          3120312D31683456316832763268365631683276327A6D332037483476396831
          36762D397A6D2D352D354839763248375635483476336831365635682D337632
          682D3256357A4D36203132683276324836762D327A6D30203468327632483676
          2D327A6D352D3468327632682D32762D327A6D30203468327632682D32762D32
          7A6D352D3468327632682D32762D327A222F3E0D0A3C2F7376673E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-mes-active.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223303030303030223E0D0A093C7061746820643D224D
          3137203368346131203120302030203120312031763136613120312030203020
          312D3120314833613120312030203020312D312D315634613120312030203020
          3120312D31683456316832763268365631683276327A6D332037483476396831
          36762D397A6D2D352D354839763248375635483476336831365635682D337632
          682D3256357A4D36203132683276324836762D327A6D30203468327632483676
          2D327A6D352D3468327632682D32762D327A6D30203468327632682D32762D32
          7A6D352D3468327632682D32762D327A222F3E0D0A3C2F7376673E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-mes-black.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223314233423142223E0D0A093C7061746820643D224D
          3137203368346131203120302030203120312031763136613120312030203020
          312D3120314833613120312030203020312D312D315634613120312030203020
          3120312D31683456316832763268365631683276327A6D332037483476396831
          36762D397A6D2D352D354839763248375635483476336831365635682D337632
          682D3256357A4D36203132683276324836762D327A6D30203468327632483676
          2D327A6D352D3468327632682D32762D327A6D30203468327632682D32762D32
          7A6D352D3468327632682D32762D327A222F3E0D0A3C2F7376673E0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-mes-disabled.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223464643313037223E0D0A093C7061746820643D224D
          3137203368346131203120302030203120312031763136613120312030203020
          312D3120314833613120312030203020312D312D315634613120312030203020
          3120312D31683456316832763268365631683276327A6D332037483476396831
          36762D397A6D2D352D354839763248375635483476336831365635682D337632
          682D3256357A6D2D392038683476324836762D327A222F3E0D0A3C2F7376673E
          0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-semana-active.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223303030303030223E0D0A093C7061746820643D224D
          3137203368346131203120302030203120312031763136613120312030203020
          312D3120314833613120312030203020312D312D315634613120312030203020
          3120312D31683456316832763268365631683276327A6D332037483476396831
          36762D397A6D2D352D354839763248375635483476336831365635682D337632
          682D3256357A6D2D392038683476324836762D327A222F3E0D0A3C2F7376673E
          0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-semana-black.svg'
      end
      item
        ImageClass = 'TdxSmartImage'
        Image.Data = {
          3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
          462D38223F3E0D0A3C7376672076696577426F783D2230203020323420323422
          20786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F73
          7667222066696C6C3D2223314233423142223E0D0A093C7061746820643D224D
          3137203368346131203120302030203120312031763136613120312030203020
          312D3120314833613120312030203020312D312D315634613120312030203020
          3120312D31683456316832763268365631683276327A6D332037483476396831
          36762D397A6D2D352D354839763248375635483476336831365635682D337632
          682D3256357A6D2D392038683476324836762D327A222F3E0D0A3C2F7376673E
          0D0A}
        FileName = 'D:\PROJECTES\GANTT\Gantt\Assets\Icons\range-semana-disabled.svg'
      end>
  end
end
