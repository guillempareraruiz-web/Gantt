object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 740
  ClientWidth = 1092
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 1092
    Height = 108
    Align = alTop
    Color = 15395562
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1092
      108)
    object Label1: TLabel
      Left = 283
      Top = 7
      Width = 41
      Height = 15
      Caption = 'Centros'
    end
    object Label2: TLabel
      Left = 346
      Top = 7
      Width = 48
      Height = 15
      Caption = 'Total OFs'
    end
    object Label3: TLabel
      Left = 18
      Top = 7
      Width = 95
      Height = 15
      Caption = 'Fecha Inicio Gantt'
    end
    object Label4: TLabel
      Left = 145
      Top = 7
      Width = 80
      Height = 15
      Caption = 'Fecha fin Gantt'
    end
    object Label5: TLabel
      Left = 772
      Top = 6
      Width = 35
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Buscar'
    end
    object Label6: TLabel
      Left = 522
      Top = 4
      Width = 48
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Ir a fecha'
    end
    object Label7: TLabel
      Left = 614
      Top = 50
      Width = 78
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Zoom timeline'
    end
    object Label8: TLabel
      Left = 419
      Top = 50
      Width = 30
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Vistas'
    end
    object lblUndoCount: TLabel
      Left = 18
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
      Left = 40
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
    object Label19: TLabel
      Left = 150
      Top = 62
      Width = 51
      Height = 15
      Caption = 'Operarios'
    end
    object btnRefresh: TButton
      Left = 1004
      Top = 22
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Refrescar'
      TabOrder = 0
      OnClick = btnRefreshClick
    end
    object spCentros: TcxSpinEdit
      Left = 283
      Top = 23
      Properties.AssignedValues.MinValue = True
      Properties.ImmediatePost = True
      TabOrder = 1
      Value = 3
      Width = 57
    end
    object cxSpinEdit2: TcxSpinEdit
      Left = 346
      Top = 23
      Properties.AssignedValues.MinValue = True
      Properties.ImmediatePost = True
      TabOrder = 2
      Value = 30
      Width = 66
    end
    object dtFechaInicioGantt: TcxDateEdit
      Left = 16
      Top = 23
      Properties.ShowTime = False
      TabOrder = 3
      Width = 121
    end
    object dtFechaFinGantt: TcxDateEdit
      Left = 143
      Top = 23
      Properties.ShowTime = False
      TabOrder = 4
      Width = 121
    end
    object SearchBox1: TSearchBox
      Left = 772
      Top = 23
      Width = 145
      Height = 23
      Anchors = [akTop, akRight]
      TabOrder = 5
      Text = 'SearchBox1'
      OnInvokeSearch = SearchBox1InvokeSearch
    end
    object RadioButton1: TRadioButton
      Left = 841
      Top = 5
      Width = 40
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'OF'
      Checked = True
      TabOrder = 6
      TabStop = True
    end
    object RadioButton2: TRadioButton
      Left = 885
      Top = 5
      Width = 40
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'OT'
      TabOrder = 7
    end
    object Button3: TButton
      Left = 921
      Top = 22
      Width = 25
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'X'
      TabOrder = 8
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 945
      Top = 22
      Width = 25
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '<'
      TabOrder = 9
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 969
      Top = 22
      Width = 25
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '>'
      TabOrder = 10
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 418
      Top = 21
      Width = 75
      Height = 25
      Caption = 'Recrear Raw'
      TabOrder = 11
      OnClick = Button6Click
    end
    object cxDateEdit1: TcxDateEdit
      Left = 520
      Top = 20
      Anchors = [akTop, akRight]
      Properties.ShowTime = False
      TabOrder = 12
      Width = 94
    end
    object Button7: TButton
      Left = 614
      Top = 19
      Width = 25
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Go'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 13
      OnClick = Button7Click
    end
    object Button8: TButton
      Tag = 1
      Left = 614
      Top = 65
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
      TabOrder = 14
      OnClick = Button8Click
    end
    object Button9: TButton
      Tag = 2
      Left = 638
      Top = 65
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
      TabOrder = 15
      OnClick = Button8Click
    end
    object Button10: TButton
      Tag = 3
      Left = 662
      Top = 65
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
      TabOrder = 16
      OnClick = Button8Click
    end
    object Button11: TButton
      Tag = 4
      Left = 686
      Top = 65
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
      TabOrder = 17
      OnClick = Button8Click
    end
    object ComboBox1: TComboBox
      Left = 826
      Top = 66
      Width = 253
      Height = 23
      Style = csDropDownList
      Anchors = [akTop, akRight]
      ItemIndex = 1
      TabOrder = 18
      Text = 'Solo ver dependencias del seleccionado'
      OnChange = ComboBox1Change
      Items.Strings = (
        'Ver todas las dependencias'
        'Solo ver dependencias del seleccionado'
        'Nunca ver dependencias')
    end
    object Button1: TButton
      Left = 638
      Top = 19
      Width = 25
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Now'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 19
      OnClick = Button1Click
    end
    object ComboBox2: TComboBox
      Left = 418
      Top = 66
      Width = 187
      Height = 23
      Style = csDropDownList
      Anchors = [akTop, akRight]
      DropDownCount = 12
      TabOrder = 20
      OnChange = ComboBox2Change
      Items.Strings = (
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
    end
    object btnUndo: TButton
      Tag = 1
      Left = 16
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
      TabOrder = 21
      OnClick = btnUndoClick
    end
    object btnRedo: TButton
      Tag = 1
      Left = 40
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
      TabOrder = 22
      OnClick = btnRedoClick
    end
    object Button12: TButton
      Tag = 1
      Left = 66
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
      TabOrder = 23
      OnClick = Button12Click
    end
    object Button13: TButton
      Tag = 1
      Left = 717
      Top = 65
      Width = 52
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Weekends'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 24
      OnClick = Button13Click
    end
    object FcxFilterOperarios: TcxCheckComboBox
      Left = 149
      Top = 78
      Properties.DropDownRows = 30
      Properties.Items = <>
      Properties.OnChange = FcxFilterOperariosPropertiesChange
      TabOrder = 25
      Width = 185
    end
    object FchkSoloFiltrados: TcxCheckBox
      Left = 224
      Top = 59
      Caption = 'Ver solo filtrados'
      Properties.Alignment = taRightJustify
      Style.TransparentBorder = False
      TabOrder = 26
    end
    object Button25: TButton
      Left = 717
      Top = 21
      Width = 51
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'BUSCAR'
      TabOrder = 27
      OnClick = Button25Click
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 712
    Width = 1092
    Height = 28
    Align = alBottom
    Color = 15395562
    ParentBackground = False
    TabOrder = 1
    object LblNodos: TLabel
      AlignWithMargins = True
      Left = 994
      Top = 4
      Width = 87
      Height = 20
      Margins.Right = 10
      Align = alRight
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Nodos: 0'
      Layout = tlCenter
      ExplicitLeft = 952
      ExplicitTop = 1
      ExplicitHeight = 26
    end
    object LblFind: TLabel
      AlignWithMargins = True
      Left = 804
      Top = 4
      Width = 177
      Height = 20
      Margins.Right = 10
      Align = alRight
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Resultado b'#250'squeda: 0/0'
      Layout = tlCenter
      ExplicitLeft = 752
    end
    object LblTiempos: TLabel
      AlignWithMargins = True
      Left = 11
      Top = 4
      Width = 80
      Height = 20
      Margins.Left = 10
      Margins.Right = 10
      Align = alLeft
      Caption = 'Tiempos Gantt:'
      Layout = tlCenter
      ExplicitHeight = 15
    end
  end
  object pnlCentros: TPanel
    Left = 0
    Top = 209
    Width = 226
    Height = 503
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'pnlCentros'
    TabOrder = 2
    object Panel2: TPanel
      Left = 0
      Top = 0
      Width = 226
      Height = 48
      Align = alTop
      BevelOuter = bvNone
      Color = 15395562
      ParentBackground = False
      TabOrder = 0
      DesignSize = (
        226
        48)
      object Shape1: TShape
        Left = 0
        Top = 47
        Width = 226
        Height = 1
        Align = alBottom
        Brush.Color = clSilver
        Pen.Color = clSilver
        ExplicitTop = 41
      end
      object Shape2: TShape
        Left = 225
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
      object Button14: TButton
        Left = 10
        Top = 24
        Width = 39
        Height = 21
        Caption = 'KPIs'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = Button14Click
      end
      object Button15: TButton
        Left = 51
        Top = 24
        Width = 39
        Height = 21
        Caption = 'KPI all'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = Button15Click
      end
      object chkShowKPIs: TCheckBox
        Left = 11
        Top = 6
        Width = 54
        Height = 17
        Caption = ' Show KPI'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = chkShowKPIsClick
      end
      object Button20: TButton
        Left = 178
        Top = 24
        Width = 39
        Height = 21
        Anchors = [akTop, akRight]
        Caption = 'Config'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = Button20Click
      end
    end
  end
  object pnlGanttContainer: TPanel
    Left = 283
    Top = 165
    Width = 359
    Height = 464
    BevelOuter = bvNone
    Caption = 'pnlGanttContainer'
    Color = clWhite
    ParentBackground = False
    TabOrder = 3
    OnResize = pnlGanttContainerResize
  end
  object Panel3: TPanel
    Left = 0
    Top = 108
    Width = 1092
    Height = 50
    Align = alTop
    Color = 15395562
    ParentBackground = False
    TabOrder = 4
    DesignSize = (
      1092
      50)
    object Label12: TLabel
      Left = 10
      Top = 4
      Width = 34
      Height = 15
      Caption = 'Nodes'
    end
    object Label18: TLabel
      Left = 113
      Top = 4
      Width = 20
      Height = 15
      Caption = 'OFs'
    end
    object Panel4: TPanel
      Left = 507
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 0
      object Label9: TLabel
        Left = 1
        Top = 1
        Width = 71
        Height = 24
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 'Total Nodos'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlBottom
        WordWrap = True
      end
      object lblNodes: TLabel
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
    object Panel5: TPanel
      Left = 580
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 1
      object Label10: TLabel
        Left = 1
        Top = 1
        Width = 71
        Height = 24
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 'Nodos visibles'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlBottom
        WordWrap = True
      end
      object lblVisible: TLabel
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
    object Panel6: TPanel
      Left = 653
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 2
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
      Left = 726
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 3
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
      Left = 799
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 4
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
      Left = 872
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 5
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
      Left = 945
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 6
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
      Left = 1018
      Top = 1
      Width = 73
      Height = 48
      Align = alRight
      TabOrder = 7
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
    object Button16: TButton
      Left = 10
      Top = 19
      Width = 21
      Height = 25
      Caption = '<<'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnClick = Button16Click
    end
    object Button17: TButton
      Left = 30
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
      TabOrder = 9
      OnClick = Button17Click
    end
    object Button19: TButton
      Left = 50
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
      TabOrder = 10
      OnClick = Button19Click
    end
    object Button18: TButton
      Left = 70
      Top = 19
      Width = 21
      Height = 25
      Caption = '>>'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 11
      OnClick = Button18Click
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
      TabOrder = 12
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
      TabOrder = 13
      OnClick = Button22Click
    end
    object Button2: TButton
      Left = 418
      Top = 6
      Width = 75
      Height = 19
      Anchors = [akTop, akRight]
      Caption = 'OF inversa'
      TabOrder = 14
      OnClick = Button2Click
    end
    object Button23: TButton
      Left = 418
      Top = 25
      Width = 75
      Height = 19
      Anchors = [akTop, akRight]
      Caption = 'OT inversa'
      TabOrder = 15
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
      TabOrder = 16
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
      TabOrder = 17
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
      TabOrder = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnResaltarOFClick
    end
  end
  object pnlBuscar: TPanel
    Left = 0
    Top = 158
    Width = 1092
    Height = 51
    Align = alTop
    Color = 15332811
    ParentBackground = False
    TabOrder = 5
    Visible = False
    DesignSize = (
      1092
      51)
    object cxScrollBox1: TcxScrollBox
      AlignWithMargins = True
      Left = 4
      Top = 1
      Width = 907
      Height = 49
      Margins.Top = 0
      Margins.Right = 180
      Margins.Bottom = 0
      Align = alClient
      BorderStyle = cxcbsNone
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = ''
      TabOrder = 0
      Transparent = True
      VertScrollBar.Visible = False
      object Label20: TLabel
        Left = 16
        Top = 3
        Width = 93
        Height = 13
        Caption = 'Orden fabricaci'#243'n'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label21: TLabel
        Left = 141
        Top = 3
        Width = 73
        Height = 13
        Caption = 'Orden trabajo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label22: TLabel
        Left = 268
        Top = 3
        Width = 36
        Height = 13
        Caption = 'Pedido'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label23: TLabel
        Left = 396
        Top = 3
        Width = 44
        Height = 13
        Caption = 'Proyecto'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label24: TLabel
        Left = 523
        Top = 3
        Width = 36
        Height = 13
        Caption = 'Cliente'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label25: TLabel
        Left = 650
        Top = 3
        Width = 40
        Height = 13
        Caption = 'Art'#237'culo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label26: TLabel
        Left = 777
        Top = 3
        Width = 33
        Height = 13
        Caption = 'Molde'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label27: TLabel
        Left = 904
        Top = 3
        Width = 36
        Height = 13
        Caption = 'Utillaje'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object cxButtonEdit1: TcxButtonEdit
        Left = 14
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 0
        Width = 121
      end
      object cxButtonEdit2: TcxButtonEdit
        Left = 141
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 1
        Width = 121
      end
      object cxButtonEdit3: TcxButtonEdit
        Left = 268
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 2
        Width = 121
      end
      object cxButtonEdit4: TcxButtonEdit
        Left = 395
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 3
        Width = 121
      end
      object cxButtonEdit5: TcxButtonEdit
        Left = 522
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 4
        Width = 121
      end
      object cxButtonEdit6: TcxButtonEdit
        Left = 649
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 5
        Width = 121
      end
      object cxButtonEdit7: TcxButtonEdit
        Left = 776
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 6
        Width = 121
      end
      object cxButtonEdit8: TcxButtonEdit
        Left = 903
        Top = 17
        ParentFont = False
        Properties.Buttons = <
          item
            Default = True
            Kind = bkEllipsis
          end>
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -11
        Style.Font.Name = 'Segoe UI'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        TabOrder = 7
        Width = 121
      end
    end
    object cxButton1: TcxButton
      Left = 1048
      Top = 19
      Width = 24
      Height = 24
      Anchors = [akTop, akRight]
      Caption = 'cxButton1'
      Colors.Normal = 12903279
      LookAndFeel.SkinName = ''
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.Data = {
        89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
        610000001974455874536F6674776172650041646F626520496D616765526561
        647971C9653C0000000B744558745469746C65005A6F6F6D3BCF09FEBC000000
        A449444154785EA5D2C10984301484616F426A7AF73461115BC1C2369093772B
        1272F36A031690537690811D1E44B244F879A0E62368A65AEB50376066ECBE12
        CAA87026647CFE082CE840D5C7FBCB1360B278431105CE4D106B014916CF4877
        360B925A402610D1A4008B04720B2804827F81502050867730FA0D7641FFFB0B
        EC12A0FB1CF8DE04BA4FE28E2E8F28D0CAE31F87ACDD00A747CE2E8088B6A213
        BD7EC0405F9BEBFFA1F53765600000000049454E44AE426082}
      PaintStyle = bpsGlyph
      TabOrder = 1
    end
    object cxButton2: TcxButton
      Left = 1072
      Top = 1
      Width = 18
      Height = 18
      Anchors = [akTop, akRight]
      Colors.Default = 15332811
      Colors.Normal = 15332811
      Colors.Hot = 15332811
      Colors.Pressed = 15332811
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = ''
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.Data = {
        89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
        610000001974455874536F6674776172650041646F626520496D616765526561
        647971C9653C0000001D744558745469746C6500436C6F73653B457869743B42
        6172733B526962626F6E3B4603B9E80000007E49444154785EA593C109C0200C
        453B98E0D5A90259ACD2A37B088E91A6A5D8102C31F5F03C7CF0210FDC886889
        FB082144A630344961A21434869C342920C531B37D09F0D970B45982DC03BD12
        545BB65E0052A28460BCA003C66553800301BA226AFE46840B77C44130F046DC
        AD4D0B2A434EAA1424E77F684CEA82154E7DE61EFB935AC9E50000000049454E
        44AE426082}
      PaintStyle = bpsGlyph
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      SpeedButtonOptions.Transparent = True
      TabOrder = 2
      OnClick = cxButton2Click
    end
    object cxButton3: TcxButton
      Left = 945
      Top = 19
      Width = 24
      Height = 24
      Anchors = [akTop, akRight]
      Caption = 'cxButton1'
      Colors.Normal = 12903279
      Colors.Pressed = 14930543
      LookAndFeel.SkinName = ''
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.Data = {
        89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
        610000001974455874536F6674776172650041646F626520496D616765526561
        647971C9653C00000014744558745469746C65004D61737465723B46696C7465
        723B0120528C0000005049444154785ED5CCB10D002008055106633926C7C600
        CD99883416BF827BE2EE4F9B0154D53B1B05AC015805AE90FD2B15008463022A
        C231038960CC00231933000B404E002D00B87F04581BC898B700DF681E5F5E4F
        2ABA0000000049454E44AE426082}
      PaintStyle = bpsGlyph
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.AllowAllUp = True
      SpeedButtonOptions.Down = True
      TabOrder = 3
    end
    object cxButton4: TcxButton
      Left = 971
      Top = 19
      Width = 24
      Height = 24
      Anchors = [akTop, akRight]
      Caption = 'cxButton1'
      Colors.Normal = 12903279
      Colors.Pressed = 14930543
      LookAndFeel.SkinName = ''
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.Data = {
        89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
        610000001974455874536F6674776172650041646F626520496D616765526561
        647971C9653C0000000F744558745469746C650053686F773B4579653B49E307
        25000000B449444154785ECDD3BB09C3301006E0A4CA1AAA33836A2D90D2CBB8
        74A1F4EA0C4EE5495CC4AD20631834C0E537FC86E340B85091145F710F0E3D2F
        22D2E40F0678EFAD004F5860A385B960FB75E0204201A928EC71768083179B4E
        B1D7E9015115DF8C47F8D0089135A1780C086AD909EED083183D6B496D27EC03
        5626E6E36411671023ABFACCDCAA5790E07A3660EF616F8160CFA0835B6D0BAC
        758C63ED162678C0009906E626730BCDEFA0FD25FEFE337D01EA94DB206117C5
        C60000000049454E44AE426082}
      PaintStyle = bpsGlyph
      SpeedButtonOptions.GroupIndex = 1
      SpeedButtonOptions.AllowAllUp = True
      TabOrder = 4
    end
    object cxButton5: TcxButton
      Left = 1023
      Top = 19
      Width = 24
      Height = 24
      Anchors = [akTop, akRight]
      Caption = 'cxButton1'
      Colors.Normal = 12698092
      LookAndFeel.SkinName = ''
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.SourceHeight = 16
      OptionsImage.Glyph.SourceWidth = 16
      OptionsImage.Glyph.Data = {
        89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
        F40000001974455874536F6674776172650041646F626520496D616765526561
        647971C9653C00000029744558745469746C650052656D6F76653B44656C6574
        653B426172733B526962626F6E3B5374616E646172643B63564830000000C249
        444154785EEDD7310AC3300C40D11ECC84F462069FDCAD27413DC8AFA1A48307
        9149FC4786883C7AEFB7CEFF0136A094F239C7787E39C755407D4F1F4F8FC7AE
        01E67877C4BC8B80880322DD5D059C1164444D76CFD537D05284C7DB40AE0000
        6171000002E2000004C4010008880300101067802322FE2B405D00D42B008803
        020010070400200E0802F8E7B5650801681C6E0700248E0838C7104F10708E03
        D13C1E083DC70942E281A0739C2322EE88FC1C6788670470E6DDFD6734CD06BC
        00DEB20CDD4F9D67C10000000049454E44AE426082}
      PaintStyle = bpsGlyph
      TabOrder = 5
    end
  end
  object popCentros: TPopupMenu
    Left = 920
    Top = 204
    object INFO3: TMenuItem
      Caption = 'Propiedades...'
      OnClick = INFO3Click
    end
  end
  object popGantt: TPopupMenu
    Left = 1008
    Top = 204
    object MenuItem1: TMenuItem
      Caption = 'Asignar fecha bloqueo'
      OnClick = MenuItem1Click
    end
    object Desactivarfechabloqueo1: TMenuItem
      Caption = 'Desactivar fecha bloqueo'
      OnClick = Desactivarfechabloqueo1Click
    end
    object Calendario1: TMenuItem
      Caption = 'Calendario'
      OnClick = Calendario1Click
      object Fechayhora1: TMenuItem
        Caption = 'Fecha y hora:'
      end
      object CentroAAA1: TMenuItem
        Caption = 'Centro:'
      end
      object NombreAAA1: TMenuItem
        Caption = 'Nombre Calendario: AAA'
      end
      object FranjalaborableSi1: TMenuItem
        Caption = 'Franja laborable: Si'
      end
      object PeriodoNoLaborableInicio1: TMenuItem
        Caption = 'Periodo NoLaborable Inicio:'
      end
      object PeriodoNoLaborableFin1: TMenuItem
        Caption = 'Periodo NoLaborable Fin:'
      end
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
  end
  object popTimeline: TPopupMenu
    Left = 920
    Top = 268
    object MenuItem2: TMenuItem
      Caption = 'PopTimeline'
    end
  end
  object popNode: TPopupMenu
    Left = 1008
    Top = 268
    object MenuItem3: TMenuItem
      AutoCheck = True
      Caption = 'Activar / bloquear'
      Checked = True
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
      OnClick = Info1Click
    end
  end
  object tmr1Sec: TTimer
    OnTimer = tmr1SecTimer
    Left = 704
    Top = 240
  end
  object MainMenu1: TMainMenu
    Left = 736
    Top = 368
    object Archivo1: TMenuItem
      Caption = 'Archivo'
      object N3: TMenuItem
        Caption = '-'
      end
      object Salir1: TMenuItem
        Caption = 'Salir'
      end
    end
    object Entidades1: TMenuItem
      Caption = 'Entidades'
      object Centros1: TMenuItem
        Caption = 'Centros'
        OnClick = Centros1Click
      end
      object Operarios1: TMenuItem
        Caption = 'Operarios'
        OnClick = Operarios1Click
      end
      object Calendarios1: TMenuItem
        Caption = 'Calendarios'
        OnClick = Calendarios1Click
      end
      object Moldes1: TMenuItem
        Caption = 'Moldes y utillajes'
        OnClick = Moldes1Click
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object Utillajes1: TMenuItem
        Caption = 'Marcadores'
        OnClick = Gestionmarcadores1Click
      end
      object Links1: TMenuItem
        Caption = 'Links'
        Enabled = False
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object CamposPersonalizados1: TMenuItem
        Caption = 'Campos Personalizados'
        OnClick = CamposPersonalizados1Click
      end
      object ReglasPlanificacion1: TMenuItem
        Caption = 'Reglas de Planificaci'#243'n'
        OnClick = ReglasPlanificacion1Click
      end
    end
    object Vistas1: TMenuItem
      Caption = 'Vistas'
      object Kanban1: TMenuItem
        Caption = 'Kanban'
        OnClick = Kanban1Click
      end
      object DispatchList1: TMenuItem
        Caption = 'Lista de Prioridades'
        OnClick = DispatchList1Click
      end
      object FiniteCapacity1: TMenuItem
        Caption = 'Planificador Capacidad Finita'
        OnClick = FiniteCapacity1Click
      end
    end
    object Ayuda1: TMenuItem
      Caption = 'Ayuda'
      object Acercade1: TMenuItem
        Caption = 'Acerca de...'
      end
    end
  end
end
