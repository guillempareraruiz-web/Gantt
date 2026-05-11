object frmPesosScoring: TfrmPesosScoring
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Pesos de Scoring'
  ClientHeight = 540
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 560
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 18
      Width = 200
      Height = 21
      Caption = 'Pesos del motor de planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlFormula: TPanel
    Left = 0
    Top = 56
    Width = 560
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 1
    object lblFormula: TLabel
      Left = 16
      Top = 8
      Width = 528
      Height = 64
      AutoSize = False
      Caption =
        'score = w1*prioridad + w2*compromiso + w3/(1+sobrenivel)'#13#10 +
        '      - w4*carga + w5*continuidad + w6*espera - w7*(coste/10)'#13#10#13#10 +
        'Subir un peso aumenta su impacto. Coste y carga restan: mas peso = castigar mas.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6316128
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 136
    Width = 560
    Height = 348
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lbl1: TLabel
      Left = 24
      Top = 16
      Width = 132
      Height = 17
      Caption = 'w1 - Prioridad de orden'
    end
    object lbl2: TLabel
      Left = 24
      Top = 60
      Width = 165
      Height = 17
      Caption = 'w2 - Compromiso (deadline)'
    end
    object lbl3: TLabel
      Left = 24
      Top = 104
      Width = 169
      Height = 17
      Caption = 'w3 - Nivel competencia / fit'
    end
    object lbl4: TLabel
      Left = 24
      Top = 148
      Width = 173
      Height = 17
      Caption = 'w4 - Carga del operario (-)'
    end
    object lbl5: TLabel
      Left = 24
      Top = 192
      Width = 187
      Height = 17
      Caption = 'w5 - Continuidad (misma OF)'
    end
    object lbl6: TLabel
      Left = 24
      Top = 236
      Width = 197
      Height = 17
      Caption = 'w6 - Espera (anti-starvation)'
    end
    object lbl7: TLabel
      Left = 24
      Top = 280
      Width = 162
      Height = 17
      Caption = 'w7 - Coste mano de obra (-)'
    end
    object edPrioridadOrden: TEdit
      Left = 360
      Top = 14
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 0
    end
    object edCompromiso: TEdit
      Left = 360
      Top = 58
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 1
    end
    object edNivelCompetencia: TEdit
      Left = 360
      Top = 102
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 2
    end
    object edCargaOperario: TEdit
      Left = 360
      Top = 146
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 3
    end
    object edContinuidad: TEdit
      Left = 360
      Top = 190
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 4
    end
    object edEspera: TEdit
      Left = 360
      Top = 234
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 5
    end
    object edCosteManoObra: TEdit
      Left = 360
      Top = 278
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 6
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 484
    Width = 560
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnDefault: TButton
      Left = 16
      Top = 14
      Width = 130
      Height = 28
      Caption = 'Restaurar defecto'
      TabOrder = 0
      OnClick = btnDefaultClick
    end
    object btnOK: TButton
      Left = 368
      Top = 14
      Width = 80
      Height = 28
      Caption = 'Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 1
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 460
      Top = 14
      Width = 80
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 2
    end
  end
end
