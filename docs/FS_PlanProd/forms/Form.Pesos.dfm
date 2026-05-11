object frmPesos: TfrmPesos
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Par'#225'metros y Pesos de Planificaci'#243'n'
  ClientHeight = 600
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clHighlight
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 8
      Width = 226
      Height = 25
      Caption = 'Pesos de Planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDescripcion: TLabel
      Left = 16
      Top = 36
      Width = 348
      Height = 15
      Caption = 'Ajusta el comportamiento del algoritmo de scoring'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlClient: TPanel
    Left = 0
    Top = 60
    Width = 720
    Height = 487
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblPesoPrioridad: TLabel
      Left = 24
      Top = 16
      Width = 137
      Height = 15
      Caption = 'Peso Prioridad de Orden:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblPrioridadHelp: TLabel
      Left = 280
      Top = 16
      Width = 419
      Height = 15
      Caption = 'Importancia de la prioridad 1-10 de la OT (default 10.0)'
    end
    object lblPesoCompromiso: TLabel
      Left = 24
      Top = 56
      Width = 130
      Height = 15
      Caption = 'Peso Compromiso (deadline):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCompromisoHelp: TLabel
      Left = 280
      Top = 56
      Width = 419
      Height = 15
      Caption = 'Penaliza retraso al deadline contractual (default 8.0)'
    end
    object lblPesoNivel: TLabel
      Left = 24
      Top = 96
      Width = 137
      Height = 15
      Caption = 'Peso Nivel de Competencia:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblNivelHelp: TLabel
      Left = 280
      Top = 96
      Width = 419
      Height = 15
      Caption = 'Premia coger justo el nivel necesario, no malgastar senior (default 3.0)'
    end
    object lblPesoCarga: TLabel
      Left = 24
      Top = 136
      Width = 121
      Height = 15
      Caption = 'Peso Carga de Operario:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCargaHelp: TLabel
      Left = 280
      Top = 136
      Width = 419
      Height = 15
      Caption = 'Penaliza operarios ya cargados de horas (default 0.5)'
    end
    object lblPesoContinuidad: TLabel
      Left = 24
      Top = 176
      Width = 96
      Height = 15
      Caption = 'Peso Continuidad:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblContinuidadHelp: TLabel
      Left = 280
      Top = 176
      Width = 419
      Height = 15
      Caption = 'Premia seguir en la misma orden (menos cambios EPI/limpieza, default 4.0)'
    end
    object lblPesoEspera: TLabel
      Left = 24
      Top = 216
      Width = 137
      Height = 15
      Caption = 'Peso Espera (anti-starvation):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblEsperaHelp: TLabel
      Left = 280
      Top = 216
      Width = 419
      Height = 15
      Caption = 'Da score a OTs que llevan tiempo en cola (default 0.05)'
    end
    object lblPesoCoste: TLabel
      Left = 24
      Top = 256
      Width = 144
      Height = 15
      Caption = 'Peso Coste Mano de Obra:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCosteHelp: TLabel
      Left = 280
      Top = 256
      Width = 419
      Height = 15
      Caption = 'Penaliza usar operarios caros (default 2.0)'
    end
    object lblFormula: TLabel
      Left = 24
      Top = 304
      Width = 95
      Height = 15
      Caption = 'F'#243'rmula del score:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtPesoPrioridad: TEdit
      Left = 200
      Top = 13
      Width = 70
      Height = 23
      Alignment = taRightJustify
      TabOrder = 0
      Text = '10.00'
    end
    object edtPesoCompromiso: TEdit
      Left = 200
      Top = 53
      Width = 70
      Height = 23
      Alignment = taRightJustify
      TabOrder = 1
      Text = '8.00'
    end
    object edtPesoNivel: TEdit
      Left = 200
      Top = 93
      Width = 70
      Height = 23
      Alignment = taRightJustify
      TabOrder = 2
      Text = '3.00'
    end
    object edtPesoCarga: TEdit
      Left = 200
      Top = 133
      Width = 70
      Height = 23
      Alignment = taRightJustify
      TabOrder = 3
      Text = '0.50'
    end
    object edtPesoContinuidad: TEdit
      Left = 200
      Top = 173
      Width = 70
      Height = 23
      Alignment = taRightJustify
      TabOrder = 4
      Text = '4.00'
    end
    object edtPesoEspera: TEdit
      Left = 200
      Top = 213
      Width = 70
      Height = 23
      Alignment = taRightJustify
      TabOrder = 5
      Text = '0.05'
    end
    object edtPesoCoste: TEdit
      Left = 200
      Top = 253
      Width = 70
      Height = 23
      Alignment = taRightJustify
      TabOrder = 6
      Text = '2.00'
    end
    object memoFormula: TMemo
      Left = 24
      Top = 326
      Width = 675
      Height = 145
      Color = clInfoBk
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 7
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 547
    Width = 720
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnDefault: TButton
      Left = 24
      Top = 12
      Width = 150
      Height = 30
      Caption = 'Restablecer Defaults'
      TabOrder = 0
      OnClick = btnDefaultClick
    end
    object btnAceptar: TButton
      Left = 504
      Top = 12
      Width = 90
      Height = 30
      Caption = 'Aceptar'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
    object btnCancelar: TButton
      Left = 600
      Top = 12
      Width = 90
      Height = 30
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 2
      OnClick = btnCancelarClick
    end
  end
end
