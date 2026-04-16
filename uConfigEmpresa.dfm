object frmConfigEmpresa: TfrmConfigEmpresa
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Configuraci'#243'n de Empresa'
  ClientHeight = 400
  ClientWidth = 520
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 520
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 200
      Height = 25
      Caption = 'Configuraci'#243'n de Empresa'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 36
      Width = 400
      Height = 15
      Caption = 'Preferencias de planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 360
    Width = 520
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 308
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Guardar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 412
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 60
    Width = 520
    Height = 300
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblSeccionRecursos: TLabel
      Left = 20
      Top = 16
      Width = 105
      Height = 15
      Caption = 'RECURSOS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object chkPlanificaOperarios: TCheckBox
      Left = 20
      Top = 40
      Width = 480
      Height = 21
      Caption = 'Planificar operarios'
      TabOrder = 0
    end
    object lblHelpOperarios: TLabel
      Left = 40
      Top = 62
      Width = 460
      Height = 28
      AutoSize = False
      Caption = 'Si est'#225' activado, los nodos pueden requerir operarios asignados y se '+
        'muestran las capacitaciones/departamentos en la UI.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object chkPlanificaMoldes: TCheckBox
      Left = 20
      Top = 96
      Width = 480
      Height = 21
      Caption = 'Planificar moldes y utillajes'
      TabOrder = 1
    end
    object lblHelpMoldes: TLabel
      Left = 40
      Top = 118
      Width = 460
      Height = 28
      AutoSize = False
      Caption = 'Si est'#225' activado, los nodos usan moldes y se considera su disponi'+
        'bilidad en los c'#225'lculos.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lblSeccionEstructura: TLabel
      Left = 20
      Top = 164
      Width = 140
      Height = 15
      Caption = 'ESTRUCTURA DE NODOS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object rbSimple: TRadioButton
      Left = 20
      Top = 188
      Width = 480
      Height = 21
      Caption = 'Simple: 1 OF = 1 OT = 1 OP'
      TabOrder = 2
    end
    object lblHelpSimple: TLabel
      Left = 40
      Top = 210
      Width = 460
      Height = 28
      AutoSize = False
      Caption = 'Cada orden de fabricaci'#243'n genera un '#250'nico nodo. Modelo plano, '+
        'recomendado para planificaci'#243'n de carga simple.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object rbCompleja: TRadioButton
      Left = 20
      Top = 244
      Width = 480
      Height = 21
      Caption = 'Compleja: 1 OF = N OT = N OP'
      TabOrder = 3
    end
    object lblHelpCompleja: TLabel
      Left = 40
      Top = 266
      Width = 460
      Height = 28
      AutoSize = False
      Caption = 'Cada OF puede tener m'#250'ltiples OTs y cada OT m'#250'ltiples operacion'+
        'es. Modelo jer'#225'rquico completo.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
end
