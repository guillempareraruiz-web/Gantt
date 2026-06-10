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
    ExplicitTop = 361
    ExplicitHeight = 239
    object pnlCentros: TPanel
      Left = 0
      Top = 0
      Width = 226
      Height = 327
      Align = alLeft
      BevelOuter = bvNone
      Caption = 'pnlCentros'
      TabOrder = 0
      ExplicitHeight = 239
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
      Left = 226
      Top = 0
      Width = 904
      Height = 327
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlGanttContainer'
      TabOrder = 1
      OnResize = pnlGanttContainerResize
      ExplicitHeight = 239
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
      ExplicitTop = 114
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
      object Label19: TLabel
        Left = 143
        Top = 62
        Width = 51
        Height = 15
        Caption = 'Operarios'
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
      object btnAutoPlanSel: TButton
        Left = 847
        Top = 52
        Width = 130
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Auto-planificar sel.'
        TabOrder = 25
        OnClick = btnAutoPlanSelClick
      end
      object btnAutoPlanAll: TButton
        Left = 982
        Top = 52
        Width = 137
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Auto-planificar todo'
        TabOrder = 26
        OnClick = btnAutoPlanAllClick
      end
      object btnDesasignarSel: TButton
        Left = 709
        Top = 52
        Width = 135
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Desasignar oper. sel.'
        TabOrder = 27
        OnClick = btnDesasignarSelClick
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
      object Button13: TButton
        Tag = 1
        Left = 709
        Top = 78
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
        TabOrder = 20
        OnClick = Button13Click
      end
      object FcxFilterOperarios: TcxCheckComboBox
        Left = 142
        Top = 78
        Properties.DropDownRows = 30
        Properties.Items = <>
        TabOrder = 21
        Width = 185
      end
      object FchkSoloFiltrados: TcxCheckBox
        Left = 217
        Top = 59
        Caption = 'Ver solo filtrados'
        Properties.Alignment = taRightJustify
        Style.TransparentBorder = False
        TabOrder = 22
      end
      object Button25: TButton
        Left = 710
        Top = 21
        Width = 51
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'BUSCAR'
        TabOrder = 23
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
        TabOrder = 24
      end
      object Panel5: TPanel
        Left = 411
        Top = 52
        Width = 36
        Height = 41
        BevelOuter = bvNone
        Color = 7699523
        ParentBackground = False
        TabOrder = 28
      end
      object Panel16: TPanel
        Left = 548
        Top = 50
        Width = 38
        Height = 41
        BevelOuter = bvNone
        Color = 9404016
        ParentBackground = False
        TabOrder = 29
      end
      object Panel17: TPanel
        Left = 506
        Top = 50
        Width = 40
        Height = 41
        BevelOuter = bvNone
        Color = 8220514
        ParentBackground = False
        TabOrder = 30
      end
      object Panel18: TPanel
        Left = 381
        Top = 52
        Width = 31
        Height = 41
        BevelOuter = bvNone
        Color = 7041597
        ParentBackground = False
        TabOrder = 31
      end
      object Panel19: TPanel
        Left = 356
        Top = 52
        Width = 31
        Height = 41
        BevelOuter = bvNone
        Color = 3553567
        ParentBackground = False
        TabOrder = 32
      end
      object Panel20: TPanel
        Left = 464
        Top = 50
        Width = 40
        Height = 41
        BevelOuter = bvNone
        Color = 6313290
        ParentBackground = False
        TabOrder = 33
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
      ExplicitTop = 223
      DesignSize = (
        1130
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
        TabOrder = 6
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
        TabOrder = 7
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
        TabOrder = 8
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
        TabOrder = 9
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
        TabOrder = 10
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
        TabOrder = 11
        OnClick = Button22Click
      end
      object Button2: TButton
        Left = 418
        Top = 6
        Width = 75
        Height = 19
        Anchors = [akTop, akRight]
        Caption = 'OF inversa'
        TabOrder = 12
        OnClick = Button2Click
      end
      object Button23: TButton
        Left = 418
        Top = 25
        Width = 75
        Height = 19
        Anchors = [akTop, akRight]
        Caption = 'OT inversa'
        TabOrder = 13
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
        TabOrder = 14
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
        TabOrder = 15
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
        TabOrder = 16
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
      DesignSize = (
        1130
        70)
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
        Left = 859
        Top = 38
        Width = 240
        Height = 29
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = '01.01.2026  -  31.12.2026'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'Segoe UI Semilight'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object Label28: TLabel
        Left = 859
        Top = 6
        Width = 240
        Height = 19
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'PROJECT NAME'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object Label29: TLabel
        Left = 914
        Top = 22
        Width = 96
        Height = 19
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'MASTER'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 12037284
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
      end
      object Label38: TLabel
        Left = 1002
        Top = 22
        Width = 96
        Height = 19
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'Modo Edici'#243'n'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 7136979
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
      object btnFocus: TButton
        Left = 488
        Top = 15
        Width = 75
        Height = 25
        Caption = 'btnFocus'
        TabOrder = 0
      end
      object btnGanttDates: TcxButton
        Left = 1104
        Top = 45
        Width = 18
        Height = 18
        Cursor = crHandPoint
        Anchors = [akTop, akRight]
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
        TabOrder = 1
        OnClick = btnGanttDatesClick
      end
      object cxButton9: TcxButton
        Left = 1104
        Top = 8
        Width = 18
        Height = 18
        Cursor = crHandPoint
        Anchors = [akTop, akRight]
        LookAndFeel.NativeStyle = False
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.SourceHeight = 16
        OptionsImage.Glyph.SourceWidth = 16
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
          F40000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C00000014744558745469746C6500416C69676E3B4A7573746966
          793B7F7E718C0000005849444154785EED93310AC0400804AF0812EE11FB12FF
          FF2D4FAB6BEC92100EA618048B65C17144C4AFB44B0A5040922577326B3E6267
          D8390EB87B7CC13105F8021C28700007700007700007706048BADEA432394107
          0516939666AFD51102320000000049454E44AE426082}
        PaintStyle = bpsGlyph
        SpeedButtonOptions.CanBeFocused = False
        SpeedButtonOptions.Flat = True
        SpeedButtonOptions.Transparent = True
        TabOrder = 2
        OnClick = cxButton9Click
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
        TabOrder = 3
        Transparent = True
        Height = 52
        Width = 56
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
      object Label8: TLabel
        Left = 25
        Top = 7
        Width = 30
        Height = 13
        Caption = 'Vistas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label6: TLabel
        Left = 180
        Top = 7
        Width = 48
        Height = 15
        Caption = 'Ir a fecha'
      end
      object Button27: TButton
        Tag = 1
        Left = 781
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
      object Panel12: TPanel
        AlignWithMargins = True
        Left = 1054
        Top = 3
        Width = 73
        Height = 42
        Margins.Left = 1
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
        TabOrder = 1
        ExplicitHeight = 38
        object Label30: TLabel
          Left = 0
          Top = 0
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Total Nodos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
          ExplicitLeft = 1
          ExplicitTop = 1
          ExplicitWidth = 71
        end
        object Label31: TLabel
          Left = 0
          Top = 16
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 14024661
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 1
          ExplicitTop = 25
          ExplicitWidth = 71
        end
      end
      object Panel13: TPanel
        AlignWithMargins = True
        Left = 752
        Top = 3
        Width = 73
        Height = 42
        Margins.Left = 1
        Margins.Right = 1
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
        TabOrder = 2
        ExplicitLeft = 829
        ExplicitHeight = 38
        object Label32: TLabel
          Left = 0
          Top = 0
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Total Nodos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 13156537
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
          ExplicitLeft = 1
          ExplicitTop = 1
          ExplicitWidth = 71
        end
        object lblNodes: TLabel
          Left = 0
          Top = 16
          Width = 73
          Height = 16
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
          ExplicitTop = 22
        end
      end
      object Panel14: TPanel
        AlignWithMargins = True
        Left = 827
        Top = 3
        Width = 73
        Height = 42
        Margins.Left = 1
        Margins.Right = 1
        Align = alRight
        BevelOuter = bvNone
        Color = 8220514
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 7041597
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 3
        ExplicitLeft = 904
        ExplicitHeight = 38
        object Label34: TLabel
          Left = 0
          Top = 0
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Nodos visibles'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 13156537
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
          ExplicitLeft = 1
          ExplicitTop = 1
          ExplicitWidth = 71
        end
        object lblVisible: TLabel
          Left = 0
          Top = 16
          Width = 73
          Height = 16
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
          ExplicitTop = 22
        end
      end
      object Panel15: TPanel
        AlignWithMargins = True
        Left = 902
        Top = 3
        Width = 73
        Height = 42
        Margins.Left = 1
        Margins.Right = 1
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
        TabOrder = 4
        ExplicitLeft = 979
        ExplicitHeight = 38
        object Label36: TLabel
          Left = 0
          Top = 0
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'xxx'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
          ExplicitLeft = 1
          ExplicitTop = 1
          ExplicitWidth = 71
        end
        object Label37: TLabel
          Left = 0
          Top = 16
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 8421631
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 1
          ExplicitTop = 25
          ExplicitWidth = 71
        end
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
        TabOrder = 5
        Text = 'gvmNormal'
        Width = 147
      end
      object Panel4: TPanel
        AlignWithMargins = True
        Left = 977
        Top = 3
        Width = 73
        Height = 42
        Margins.Left = 1
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
        TabOrder = 6
        ExplicitLeft = 1054
        ExplicitHeight = 38
        object Label9: TLabel
          Left = 0
          Top = 0
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = 'Total Nodos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlBottom
          WordWrap = True
          ExplicitLeft = 1
          ExplicitTop = 1
          ExplicitWidth = 71
        end
        object Label10: TLabel
          Left = 0
          Top = 16
          Width = 73
          Height = 16
          Align = alTop
          Alignment = taCenter
          AutoSize = False
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 12703487
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 1
          ExplicitTop = 25
          ExplicitWidth = 71
        end
      end
      object cxDateEdit1: TcxDateEdit
        Left = 178
        Top = 21
        ParentFont = False
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
        TabOrder = 7
        Width = 103
      end
      object btnIr: TcxButton
        Left = 282
        Top = 22
        Width = 29
        Height = 20
        Caption = 'Ir'
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 8
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
        Height = 20
        Caption = 'Hoy'
        LookAndFeel.Kind = lfUltraFlat
        LookAndFeel.NativeStyle = False
        LookAndFeel.SkinName = 'Sharp'
        SpeedButtonOptions.CanBeFocused = False
        TabOrder = 9
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnHoyClick
      end
    end
  end
  object popCentros: TPopupMenu
    Left = 744
    Top = 428
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
    Left = 832
    Top = 428
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
  end
  object popTimeline: TPopupMenu
    Left = 744
    Top = 372
    object MenuItem2: TMenuItem
      Caption = 'PopTimeline'
    end
  end
  object popNode: TPopupMenu
    OnPopup = popNodePopup
    Left = 832
    Top = 372
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
      494C01010C001800040018001800FFFFFFFF2100FFFFFFFFFFFFFFFF424D3600
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
      00000000000000000000000000000000}
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
