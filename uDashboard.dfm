object frmDashboard: TfrmDashboard
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Dashboard'
  ClientHeight = 784
  ClientWidth = 900
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
    Width = 900
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      900
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
      Left = 777
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
    end
    object lblPendingSync: TLabel
      Left = 352
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
      Left = 867
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
    end
  end
  object pnlCards: TPanel
    Left = 0
    Top = 70
    Width = 900
    Height = 714
    Align = alClient
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 1
    object pnlEmpresa: TPanel
      Left = 24
      Top = 24
      Width = 280
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
        Left = 16
        Top = 40
        Width = 248
        Height = 25
        AutoSize = False
        Caption = '--'
        EllipsisPosition = epEndEllipsis
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3553567
        Font.Height = -19
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblEmpresaCodigo: TLabel
        Left = 16
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
    end
    object pnlProyecto: TPanel
      Left = 320
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
        Font.Height = -19
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
      Left = 616
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
        Font.Height = -19
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
