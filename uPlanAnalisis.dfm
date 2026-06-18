object frmPlanAnalisis: TfrmPlanAnalisis
  Left = 0
  Top = 0
  Caption = 'An'#225'lisis del plan'
  ClientHeight = 700
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  WindowState = wsMaximized
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblDesde: TLabel
      Left = 16
      Top = 16
      Width = 38
      Height = 15
      Caption = 'Desde:'
    end
    object lblGran: TLabel
      Left = 210
      Top = 16
      Width = 75
      Height = 15
      Caption = 'Granularidad:'
    end
    object lblNum: TLabel
      Left = 400
      Top = 16
      Width = 53
      Height = 15
      Caption = 'Periodos:'
    end
    object dtDesde: TDateTimePicker
      Left = 64
      Top = 12
      Width = 130
      Height = 23
      Date = 45000.000000000000000000
      Time = 0.000000000000000000
      TabOrder = 0
    end
    object cmbGran: TComboBox
      Left = 291
      Top = 12
      Width = 100
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
    object spNum: TSpinEdit
      Left = 459
      Top = 12
      Width = 70
      Height = 24
      MaxValue = 120
      MinValue = 1
      TabOrder = 2
      Value = 14
    end
    object btnActualizar: TButton
      Left = 552
      Top = 11
      Width = 130
      Height = 26
      Caption = 'Actualizar'
      TabOrder = 3
      OnClick = btnActualizarClick
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 48
    Width = 250
    Height = 652
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object tvNav: TTreeView
      Left = 0
      Top = 0
      Width = 250
      Height = 652
      Align = alClient
      BorderStyle = bsNone
      Color = 16448250
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      HideSelection = False
      Indent = 19
      ParentFont = False
      ReadOnly = True
      RowSelect = True
      ShowRoot = False
      TabOrder = 0
      OnClick = tvNavClick
      OnCustomDrawItem = tvNavCustomDrawItem
    end
  end
  object splV: TSplitter
    Left = 250
    Top = 48
    Width = 5
    Height = 652
    ExplicitLeft = 250
    ExplicitTop = 48
  end
  object pc: TPageControl
    Left = 255
    Top = 48
    Width = 845
    Height = 652
    Align = alClient
    TabOrder = 2
  end
end
