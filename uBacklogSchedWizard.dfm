object frmBacklogSchedWizard: TfrmBacklogSchedWizard
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Asistente de planificaci'#243'n'
  ClientHeight = 700
  ClientWidth = 820
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object wcMain: TdxWizardControl
    Left = 0
    Top = 0
    Width = 820
    Height = 700
    Buttons.Back.Caption = 'Atr'#225's'
    Buttons.Cancel.Caption = 'Cancelar'
    Buttons.CustomButtons.Buttons = <>
    Buttons.Finish.Caption = 'Planificar'
    Buttons.Next.Caption = 'Siguiente'
    OnButtonClick = wcMainButtonClick
    OnPageChanged = wcMainPageChanged
    OnPageChanging = wcMainPageChanging
    object pgGranularidad: TdxWizardControlPage
      Header.Description = 'Decide la granularidad del resultado en el Gantt.'
      Header.Title = 'C'#243'mo agrupar los nodos'
      object lblGranIntro: TLabel
        Left = 28
        Top = 16
        Width = 740
        Height = 30
        AutoSize = False
        Caption = 
          'Cada operaci'#243'n (OP) puede convertirse en un nodo, o puedes agrup' +
          'arlas. Elige c'#243'mo quieres ver la selecci'#243'n en el Gantt:'
        WordWrap = True
      end
      object lblGranOP: TLabel
        Left = 52
        Top = 60
        Width = 315
        Height = 15
        Caption = 'Un nodo por cada operaci'#243'n. M'#225'ximo detalle y trazabilidad.'
      end
      object lblGranCentro: TLabel
        Left = 52
        Top = 92
        Width = 342
        Height = 15
        Caption = 'Agrupa las operaciones del mismo centro en un solo nodo (lote).'
      end
      object lblGranTodo: TLabel
        Left = 52
        Top = 124
        Width = 331
        Height = 15
        Caption = 'Agrupa toda la selecci'#243'n en un '#250'nico nodo (suma duraciones).'
      end
      object pbIlustracion: TPaintBox
        Left = 28
        Top = 164
        Width = 760
        Height = 360
        OnPaint = pbIlustracionPaint
      end
      object rbGranOP: TRadioButton
        Left = 28
        Top = 58
        Width = 21
        Height = 17
        TabOrder = 0
        OnClick = rbGranClick
      end
      object rbGranCentro: TRadioButton
        Left = 28
        Top = 90
        Width = 21
        Height = 17
        TabOrder = 1
        OnClick = rbGranClick
      end
      object rbGranTodo: TRadioButton
        Left = 28
        Top = 122
        Width = 21
        Height = 17
        TabOrder = 2
        OnClick = rbGranClick
      end
    end
    object pgCentro: TdxWizardControlPage
      Header.Description = 
        'La selecci'#243'n abarca varios centros. Elige d'#243'nde colocar el nodo ' +
        'agrupado.'
      Header.Title = 'Centro destino'
      object lblCentroIntro: TLabel
        Left = 28
        Top = 16
        Width = 740
        Height = 45
        AutoSize = False
        Caption = 
          'Has elegido agrupar toda la selecci'#243'n en un solo nodo, pero las ' +
          'operaciones pertenecen a centros distintos. Un nodo solo puede v' +
          'ivir en un centro: indica en cu'#225'l quieres colocarlo.'
        WordWrap = True
      end
      object pbCentro: TPaintBox
        Left = 28
        Top = 110
        Width = 760
        Height = 390
        OnPaint = pbCentroPaint
      end
      object cbCentroDestino: TComboBox
        Left = 28
        Top = 70
        Width = 360
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = rbGranClick
      end
    end
    object pgTemporal: TdxWizardControlPage
      Header.Description = 'Hacia d'#243'nde y desde cu'#225'ndo planificar.'
      Header.Title = 'Direcci'#243'n y fecha'
      object lblFecha: TLabel
        Left = 360
        Top = 28
        Width = 86
        Height = 15
        Caption = 'Planificar desde:'
      end
      object pbTemporal: TPaintBox
        Left = 28
        Top = 96
        Width = 760
        Height = 390
        OnPaint = pbTemporalPaint
      end
      object gbDireccion: TGroupBox
        Left = 28
        Top = 8
        Width = 310
        Height = 76
        Caption = '  Direcci'#243'n  '
        TabOrder = 0
        object rbForward: TRadioButton
          Left = 16
          Top = 24
          Width = 130
          Height = 17
          Caption = 'Hacia delante'
          Checked = True
          TabOrder = 0
          TabStop = True
          OnClick = rbModoClick
        end
        object rbBackward: TRadioButton
          Left = 16
          Top = 48
          Width = 200
          Height = 17
          Caption = 'Hacia atr'#225's'
          TabOrder = 1
          OnClick = rbModoClick
        end
      end
      object gbOrden: TGroupBox
        Left = 360
        Top = 56
        Width = 408
        Height = 28
        Caption = ''
        TabOrder = 1
        object rbOrdenFecha: TRadioButton
          Left = 12
          Top = 4
          Width = 190
          Height = 17
          Caption = 'Por fecha de compromiso'
          Checked = True
          TabOrder = 0
          TabStop = True
        end
        object rbOrdenPrio: TRadioButton
          Left = 226
          Top = 4
          Width = 150
          Height = 17
          Caption = 'Por prioridad'
          TabOrder = 1
        end
      end
      object dtFechaBase: TDateTimePicker
        Left = 466
        Top = 24
        Width = 130
        Height = 23
        Date = 45000.000000000000000000
        Time = 45000.000000000000000000
        TabOrder = 2
      end
    end
    object pgAjustes: TdxWizardControlPage
      Header.Description = 
        'Opcional: c'#243'mo rellenar huecos y separar nodos. Los valores por ' +
        'defecto suelen bastar.'
      Header.Title = 'Ajustes avanzados'
      object lblAjustesIntro: TLabel
        Left = 28
        Top = 16
        Width = 740
        Height = 18
        AutoSize = False
        Caption = 
          'Si no los conoces, deja los valores por defecto. La ilustraci'#243'n ' +
          'muestra c'#243'mo encaja un nodo nuevo entre los existentes.'
        WordWrap = True
      end
      object lblPlacement: TLabel
        Left = 28
        Top = 48
        Width = 120
        Height = 15
        Caption = 'Colocaci'#243'n en huecos:'
      end
      object lblHueco: TLabel
        Left = 360
        Top = 48
        Width = 138
        Height = 15
        Caption = 'Hueco m'#237'nimo (minutos):'
      end
      object lblPct: TLabel
        Left = 28
        Top = 84
        Width = 172
        Height = 15
        Caption = '% m'#237'nimo del nodo en el hueco:'
      end
      object lblDist: TLabel
        Left = 360
        Top = 84
        Width = 193
        Height = 15
        Caption = 'Distancia m'#237'nima entre nodos (min):'
      end
      object pbAjustes: TPaintBox
        Left = 28
        Top = 120
        Width = 760
        Height = 380
        OnPaint = pbAjustesPaint
      end
      object cbPlacement: TComboBox
        Left = 170
        Top = 45
        Width = 170
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = rbModoClick
      end
      object seHueco: TSpinEdit
        Left = 600
        Top = 45
        Width = 90
        Height = 24
        MaxValue = 10000
        MinValue = 0
        TabOrder = 1
        Value = 30
        OnChange = rbModoClick
      end
      object sePct: TSpinEdit
        Left = 240
        Top = 81
        Width = 90
        Height = 24
        MaxValue = 100
        MinValue = 0
        TabOrder = 2
        Value = 50
        OnChange = rbModoClick
      end
      object seDist: TSpinEdit
        Left = 600
        Top = 81
        Width = 90
        Height = 24
        MaxValue = 10000
        MinValue = 0
        TabOrder = 3
        Value = 0
        OnChange = rbModoClick
      end
    end
    object pgResumen: TdxWizardControlPage
      Header.Description = 'Revisa antes de planificar.'
      Header.Title = 'Resumen'
      object lblResumen: TLabel
        Left = 28
        Top = 14
        Width = 760
        Height = 22
        AutoSize = False
        Caption = 'Resumen...'
        WordWrap = False
      end
      object pbResumen: TPaintBox
        Left = 28
        Top = 44
        Width = 760
        Height = 400
        OnPaint = pbResumenPaint
      end
      object btnVerTiempos: TButton
        Left = 560
        Top = 456
        Width = 228
        Height = 34
        Caption = 'Ver tiempos calculados...'
        TabOrder = 0
        OnClick = btnVerTiemposClick
      end
    end
  end
end
