object frmGenerarNodosDemo: TfrmGenerarNodosDemo
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Generar Nodos Demo'
  ClientHeight = 560
  ClientWidth = 600
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
    Width = 600
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
      Caption = 'Generar Nodos Demo'
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
      Caption = '--'
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
    Top = 520
    Width = 600
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnGenerar: TButton
      Left = 388
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Generar'
      Default = True
      TabOrder = 0
      OnClick = btnGenerarClick
    end
    object btnCancel: TButton
      Left = 492
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
    Width = 600
    Height = 460
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblSeccionEstructura: TLabel
      Left = 20
      Top = 16
      Width = 100
      Height = 15
      Caption = 'ESTRUCTURA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object rbSimple: TRadioButton
      Left = 20
      Top = 40
      Width = 280
      Height = 21
      Caption = 'Simple (1 OF = 1 OT = 1 OP)'
      TabOrder = 0
      OnClick = EstructuraChange
    end
    object rbCompleja: TRadioButton
      Left = 20
      Top = 64
      Width = 280
      Height = 21
      Caption = 'Compleja (1 OF = N OT = N OP)'
      TabOrder = 1
      OnClick = EstructuraChange
    end
    object lblSeccionCantidades: TLabel
      Left = 20
      Top = 100
      Width = 100
      Height = 15
      Caption = 'CANTIDADES'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblNumOFs: TLabel
      Left = 20
      Top = 126
      Width = 200
      Height = 17
      Caption = 'N'#250'mero de '#243'rdenes de fabricaci'#243'n:'
    end
    object spNumOFs: TcxSpinEdit
      Left = 230
      Top = 124
      Properties.MaxValue = 500.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 2
      Value = 20
      Width = 80
    end
    object lblOTsPorOF: TLabel
      Left = 20
      Top = 154
      Width = 200
      Height = 17
      Caption = 'OTs por OF (solo en modo Compleja):'
    end
    object spOTsPorOF: TcxSpinEdit
      Left = 230
      Top = 152
      Properties.MaxValue = 20.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 3
      Value = 3
      Width = 80
    end
    object lblOpsPorOT: TLabel
      Left = 20
      Top = 182
      Width = 200
      Height = 17
      Caption = 'Operaciones por OT:'
    end
    object spOpsPorOT: TcxSpinEdit
      Left = 230
      Top = 180
      Properties.MaxValue = 20.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 4
      Value = 4
      Width = 80
    end
    object lblPctPlanificados: TLabel
      Left = 20
      Top = 210
      Width = 200
      Height = 17
      Caption = '% nodos planificados (con fechas):'
    end
    object spPctPlanificados: TcxSpinEdit
      Left = 230
      Top = 208
      Properties.MaxValue = 100.000000000000000000
      TabOrder = 5
      Value = 70
      Width = 80
    end
    object lblSeccionFechas: TLabel
      Left = 20
      Top = 248
      Width = 100
      Height = 15
      Caption = 'RANGO DE FECHAS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblFechaInicio: TLabel
      Left = 20
      Top = 274
      Width = 90
      Height = 17
      Caption = 'Fecha inicio:'
    end
    object dtFechaInicio: TcxDateEdit
      Left = 130
      Top = 272
      TabOrder = 6
      Width = 120
    end
    object lblFechaFin: TLabel
      Left = 280
      Top = 274
      Width = 70
      Height = 17
      Caption = 'Fecha fin:'
    end
    object dtFechaFin: TcxDateEdit
      Left = 360
      Top = 272
      TabOrder = 7
      Width = 120
    end
    object lblSeccionRecursos: TLabel
      Left = 20
      Top = 310
      Width = 100
      Height = 15
      Caption = 'RECURSOS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object chkIncluirOperarios: TCheckBox
      Left = 20
      Top = 332
      Width = 280
      Height = 21
      Caption = 'Asignar operarios a los nodos'
      TabOrder = 8
    end
    object chkIncluirMoldes: TCheckBox
      Left = 20
      Top = 356
      Width = 280
      Height = 21
      Caption = 'Asignar moldes a los nodos'
      TabOrder = 9
    end
    object lblSeccionOpciones: TLabel
      Left = 20
      Top = 390
      Width = 100
      Height = 15
      Caption = 'OPCIONES'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object chkLimpiarExistentes: TCheckBox
      Left = 20
      Top = 412
      Width = 480
      Height = 21
      Caption = 'Eliminar nodos existentes del proyecto antes de generar'
      Checked = True
      State = cbChecked
      TabOrder = 10
    end
    object chkGenerarDependencias: TCheckBox
      Left = 20
      Top = 434
      Width = 480
      Height = 21
      Caption = 'Encadenar operaciones de la misma OT con dependencias FS'
      Checked = True
      State = cbChecked
      TabOrder = 11
    end
  end
end
