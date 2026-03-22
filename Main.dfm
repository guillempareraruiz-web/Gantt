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
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 1092
    Height = 95
    Align = alTop
    Color = 15395562
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1092
      95)
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
    Top = 145
    Width = 226
    Height = 567
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
    Top = 95
    Width = 1092
    Height = 50
    Align = alTop
    Color = 15395562
    ParentBackground = False
    TabOrder = 4
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
      Caption = 'OF inversa'
      TabOrder = 14
      OnClick = Button2Click
    end
    object Button23: TButton
      Left = 418
      Top = 25
      Width = 75
      Height = 19
      Caption = 'OT inversa'
      TabOrder = 15
      OnClick = Button23Click
    end
  end
  object popCentros: TPopupMenu
    Left = 920
    Top = 204
    object PopCentros1: TMenuItem
      Caption = 'Enabled'
      OnClick = PopCentros1Click
    end
    object INFO3: TMenuItem
      Caption = 'INFO'
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
    object INFO2: TMenuItem
      Caption = 'INFO'
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
      object aa1: TMenuItem
        Caption = 'xxx'
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
      Caption = 'Enabled'
      Checked = True
      OnClick = MenuItem3Click
    end
    object LibreMovimiento1: TMenuItem
      AutoCheck = True
      Caption = 'Libre Movimiento'
      OnClick = LibreMovimiento1Click
    end
    object Move1h1: TMenuItem
      Caption = 'Move 1h'
      OnClick = Move1h1Click
    end
    object Resetduracinoriginal1: TMenuItem
      Caption = 'Reset duraci'#243'n original'
      OnClick = Resetduracinoriginal1Click
    end
    object ShiftRow2: TMenuItem
      Caption = 'ShiftRow'
      OnClick = ShiftRow2Click
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
end
