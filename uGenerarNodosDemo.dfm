object frmGenerarNodosDemo: TfrmGenerarNodosDemo
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Generar Nodos Demo'
  ClientHeight = 790
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
      Width = 186
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
      Width = 10
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
    Top = 750
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
    Height = 601
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitHeight = 556
    object lblSeccionEstructura: TLabel
      Left = 20
      Top = 16
      Width = 68
      Height = 13
      Caption = 'ESTRUCTURA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744448
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSeccionCantidades: TLabel
      Left = 20
      Top = 84
      Width = 66
      Height = 13
      Caption = 'CANTIDADES'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744448
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblNumOFs: TLabel
      Left = 20
      Top = 110
      Width = 186
      Height = 15
      Caption = 'N'#250'mero de '#243'rdenes de fabricaci'#243'n:'
    end
    object lblOTsPorOF: TLabel
      Left = 20
      Top = 138
      Width = 198
      Height = 15
      Caption = 'OTs por OF (solo en modo Compleja):'
    end
    object lblOpsPorOT: TLabel
      Left = 20
      Top = 166
      Width = 107
      Height = 15
      Caption = 'Operaciones por OT:'
    end
    object lblPctPlanificados: TLabel
      Left = 20
      Top = 194
      Width = 184
      Height = 15
      Caption = '% nodos planificados (con fechas):'
    end
    object lblSeccionFechas: TLabel
      Left = 20
      Top = 268
      Width = 113
      Height = 13
      Caption = 'INICIO PLANIFICACI'#211'N'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744448
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblFechaInicio: TLabel
      Left = 20
      Top = 294
      Width = 388
      Height = 15
      Caption = 
        'Planificar a partir de (el fin lo calcula el motor seg'#250'n durac'#237#243 +
        'n/colisiones):'
    end
    object lblSeccionRecursos: TLabel
      Left = 20
      Top = 326
      Width = 55
      Height = 13
      Caption = 'RECURSOS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744448
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSeccionOpciones: TLabel
      Left = 20
      Top = 414
      Width = 52
      Height = 13
      Caption = 'OPCIONES'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744448
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 20
      Top = 222
      Width = 101
      Height = 15
      Caption = '% nodos sin centro'
    end
    object lblSeccionMotor: TLabel
      Left = 20
      Top = 530
      Width = 39
      Height = 13
      Caption = 'MOTOR'
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
      Width = 198
      Height = 21
      Caption = '  Simple (1 OF = 1 OT = 1 OP)'
      TabOrder = 0
      OnClick = EstructuraChange
    end
    object rbCompleja: TRadioButton
      Left = 230
      Top = 40
      Width = 280
      Height = 21
      Caption = '  Compleja (1 OF = N OT = N OP)'
      TabOrder = 1
      OnClick = EstructuraChange
    end
    object spNumOFs: TcxSpinEdit
      Left = 230
      Top = 108
      Properties.MaxValue = 500.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 2
      Value = 20
      Width = 80
    end
    object spOTsPorOF: TcxSpinEdit
      Left = 230
      Top = 136
      Properties.MaxValue = 20.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 3
      Value = 3
      Width = 80
    end
    object spOpsPorOT: TcxSpinEdit
      Left = 230
      Top = 164
      Properties.MaxValue = 20.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 4
      Value = 4
      Width = 80
    end
    object spPctPlanificados: TcxSpinEdit
      Left = 230
      Top = 192
      Properties.MaxValue = 100.000000000000000000
      TabOrder = 5
      Value = 70
      Width = 80
    end
    object dtFechaInicio: TcxDateEdit
      Left = 428
      Top = 291
      TabOrder = 6
      Width = 120
    end
    object chkIncluirOperarios: TCheckBox
      Left = 20
      Top = 348
      Width = 280
      Height = 21
      Caption = 'Asignar operarios a los nodos'
      TabOrder = 7
    end
    object chkIncluirMoldes: TCheckBox
      Left = 20
      Top = 372
      Width = 280
      Height = 21
      Caption = 'Asignar moldes a los nodos'
      TabOrder = 8
    end
    object chkLimpiarExistentes: TCheckBox
      Left = 20
      Top = 436
      Width = 480
      Height = 21
      Caption = 'Eliminar nodos existentes del proyecto antes de generar'
      Checked = True
      State = cbChecked
      TabOrder = 10
    end
    object chkGenerarDependencias: TCheckBox
      Left = 20
      Top = 458
      Width = 480
      Height = 21
      Caption = 'Encadenar operaciones de la misma OT con dependencias FS'
      Checked = True
      State = cbChecked
      TabOrder = 9
    end
    object spPctSinCentro: TcxSpinEdit
      Left = 230
      Top = 220
      Properties.MaxValue = 100.000000000000000000
      TabOrder = 11
      Value = 2
      Width = 80
    end
    object chkGenerarOptimizadosRandom: TCheckBox
      Left = 20
      Top = 480
      Width = 480
      Height = 21
      Caption = 'Con algunos nodos aleatoriamente Optimizados'
      Checked = True
      State = cbChecked
      TabOrder = 12
    end
    object chkGenerarFabricacionRandom: TCheckBox
      Left = 20
      Top = 502
      Width = 480
      Height = 21
      Caption = 'Con algunos nodos parcialmente ya fabricados'
      Checked = True
      State = cbChecked
      TabOrder = 13
    end
    object pnlMotor: TPanel
      Left = 20
      Top = 548
      Width = 550
      Height = 114
      BevelOuter = bvNone
      TabOrder = 14
      object rbMotorPRO5: TRadioButton
        Left = 0
        Top = 2
        Width = 550
        Height = 21
        Caption =
          'PRO bulk file (M5): RAM + BULK INSERT desde fichero - el m'#225's r'#225'pido'
        Checked = True
        TabOrder = 0
        TabStop = True
      end
      object rbMotorPRO4: TRadioButton
        Left = 0
        Top = 24
        Width = 550
        Height = 21
        Caption = 'PRO bulk ADO (M4): RAM + carga binaria ADO'
        TabOrder = 1
      end
      object rbMotorPRO3: TRadioButton
        Left = 0
        Top = 46
        Width = 550
        Height = 21
        Caption = 'PRO staging (M3): RAM + INSERT texto + set-based'
        TabOrder = 2
      end
      object rbMotorPRO: TRadioButton
        Left = 0
        Top = 68
        Width = 550
        Height = 21
        Caption = 'PRO multifila (M2): RAM + INSERT multifila'
        TabOrder = 3
      end
      object rbMotorClasico: TRadioButton
        Left = 0
        Top = 90
        Width = 550
        Height = 21
        Caption = 'Cl'#225'sico (M1): motor de planificaci'#243'n + BD - para comparar'
        TabOrder = 4
      end
    end
  end
end
