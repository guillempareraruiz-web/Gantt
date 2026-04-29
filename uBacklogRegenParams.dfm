object frmBacklogRegenParams: TfrmBacklogRegenParams
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Regenerar Backlog (demo)'
  ClientHeight = 340
  ClientWidth = 420
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 222
      Height = 25
      Caption = 'Regenerar Backlog (demo)'
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
      Width = 275
      Height = 15
      Caption = 'Indica el n'#250'mero de registros a generar en el staging'
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
    Top = 300
    Width = 420
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnAceptar: TButton
      Left = 220
      Top = 6
      Width = 90
      Height = 28
      Caption = 'Regenerar'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 316
      Top = 6
      Width = 90
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
    Width = 420
    Height = 240
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblNumOFs: TLabel
      Left = 24
      Top = 20
      Width = 75
      Height = 15
      Caption = 'N'#250'mero de OFs'
    end
    object lblNumCom: TLabel
      Left = 24
      Top = 56
      Width = 105
      Height = 15
      Caption = 'N'#250'mero de Comandas'
    end
    object lblNumPrj: TLabel
      Left = 24
      Top = 92
      Width = 106
      Height = 15
      Caption = 'N'#250'mero de Proyectos'
    end
    object lblAviso: TLabel
      Left = 24
      Top = 156
      Width = 372
      Height = 60
      AutoSize = False
      Caption =
        'Se borrar'#225'n los datos demo anteriores (OrigenERP = DEMO) y se re' +
        'generar'#225'n con los nuevos valores. Si est'#225' marcada la opci'#243'n, ta' +
        'mbi'#233'n se vaciar'#225' el plan del proyecto activo (nodos, dependenci' +
        'as).'
      WordWrap = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6710886
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object spNumOFs: TcxSpinEdit
      Left = 220
      Top = 16
      Properties.MaxValue = 10000.000000000000000000
      Properties.MinValue = 0.000000000000000000
      TabOrder = 0
      Value = 25
      Width = 120
    end
    object spNumCom: TcxSpinEdit
      Left = 220
      Top = 52
      Properties.MaxValue = 10000.000000000000000000
      Properties.MinValue = 0.000000000000000000
      TabOrder = 1
      Value = 12
      Width = 120
    end
    object spNumPrj: TcxSpinEdit
      Left = 220
      Top = 88
      Properties.MaxValue = 10000.000000000000000000
      Properties.MinValue = 0.000000000000000000
      TabOrder = 2
      Value = 4
      Width = 120
    end
    object chkVaciarPlan: TCheckBox
      Left = 24
      Top = 124
      Width = 372
      Height = 20
      Caption = 'Vaciar plan del proyecto activo antes de regenerar (nodos, depen'#39'as)'
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
  end
end
