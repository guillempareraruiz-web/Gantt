object frmOperariosVisibles: TfrmOperariosVisibles
  Left = 0
  Top = 0
  Caption = 'Operarios visibles'
  ClientHeight = 540
  ClientWidth = 480
  Color = 15789544
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 140
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 12
      Width = 350
      Height = 21
      Caption = 'Aplicar criterios para auto-seleccionar operarios'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDept: TLabel
      Left = 16
      Top = 50
      Width = 86
      Height = 17
      Caption = 'Departamento:'
    end
    object lblCap: TLabel
      Left = 16
      Top = 82
      Width = 79
      Height = 17
      Caption = 'Capacitaci'#243'n:'
    end
    object cbDept: TComboBox
      Left = 116
      Top = 47
      Width = 240
      Height = 25
      Style = csDropDownList
      TabOrder = 0
    end
    object cbCap: TComboBox
      Left = 116
      Top = 79
      Width = 240
      Height = 25
      Style = csDropDownList
      TabOrder = 1
    end
    object btnAplicarCriterios: TButton
      Left = 365
      Top = 78
      Width = 100
      Height = 27
      Caption = 'Aplicar criterios'
      TabOrder = 2
      OnClick = btnAplicarCriteriosClick
    end
  end
  object pnlList: TPanel
    Left = 0
    Top = 140
    Width = 480
    Height = 350
    Align = alClient
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 1
    object lblOperarios: TLabel
      Left = 16
      Top = 8
      Width = 280
      Height = 17
      Caption = 'Selecci'#243'n manual de operarios visibles:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6316128
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object clOperarios: TCheckListBox
      Left = 16
      Top = 32
      Width = 449
      Height = 308
      ItemHeight = 17
      TabOrder = 0
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 490
    Width = 480
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 2
    object btnTodos: TButton
      Left = 16
      Top = 12
      Width = 90
      Height = 27
      Caption = 'Marcar todos'
      TabOrder = 0
      OnClick = btnTodosClick
    end
    object btnNinguno: TButton
      Left = 112
      Top = 12
      Width = 100
      Height = 27
      Caption = 'Desmarcar todos'
      TabOrder = 1
      OnClick = btnNingunoClick
    end
    object btnOK: TButton
      Left = 296
      Top = 12
      Width = 80
      Height = 27
      Caption = 'Aceptar'
      Default = True
      TabOrder = 2
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 384
      Top = 12
      Width = 80
      Height = 27
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 3
      OnClick = btnCancelClick
    end
  end
end
