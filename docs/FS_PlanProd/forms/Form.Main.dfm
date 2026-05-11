object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'FS - Planificador de Producci'#243'n'
  ClientHeight = 480
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = clHighlight
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 8
      Width = 367
      Height = 33
      Caption = 'Planificador de Producci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -27
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 16
      Top = 48
      Width = 290
      Height = 17
      Caption = 'Demo VCL - Sector qu'#237'mico - Delphi 10.4'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 80
    Width = 720
    Height = 381
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblFecha: TLabel
      Left = 24
      Top = 24
      Width = 153
      Height = 15
      Caption = 'Fecha simulada de planificaci'#243'n:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnOperarios: TButton
      Left = 24
      Top = 104
      Width = 200
      Height = 60
      Caption = 'Operarios y Polivalencia'
      TabOrder = 0
      OnClick = btnOperariosClick
    end
    object btnOrdenes: TButton
      Left = 240
      Top = 104
      Width = 200
      Height = 60
      Caption = #211'rdenes de Trabajo'
      TabOrder = 1
      OnClick = btnOrdenesClick
    end
    object btnPesos: TButton
      Left = 456
      Top = 104
      Width = 200
      Height = 60
      Caption = 'Par'#225'metros y Pesos'
      TabOrder = 2
      OnClick = btnPesosClick
    end
    object btnEjecutar: TButton
      Left = 24
      Top = 200
      Width = 416
      Height = 80
      Caption = 'Ejecutar Planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnEjecutarClick
    end
    object btnAsignaciones: TButton
      Left = 456
      Top = 200
      Width = 200
      Height = 80
      Caption = 'Ver Asignaciones'
      TabOrder = 4
      OnClick = btnAsignacionesClick
    end
    object edtFecha: TDateTimePicker
      Left = 24
      Top = 56
      Width = 130
      Height = 23
      Date = 45869.000000000000000000
      Time = 0.333333333333333300
      TabOrder = 5
    end
    object edtHora: TDateTimePicker
      Left = 160
      Top = 56
      Width = 90
      Height = 23
      Date = 45869.000000000000000000
      Time = 0.333333333333333300
      Kind = dtkTime
      TabOrder = 6
    end
    object btnAplicarFecha: TButton
      Left = 256
      Top = 56
      Width = 100
      Height = 23
      Caption = 'Aplicar fecha'
      TabOrder = 7
      OnClick = btnAplicarFechaClick
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 461
    Width = 720
    Height = 19
    Panels = <
      item
        Width = 130
      end
      item
        Width = 130
      end
      item
        Width = 160
      end
      item
        Width = 250
      end>
  end
  object MainMenu1: TMainMenu
    Left = 600
    Top = 16
    object miArchivo: TMenuItem
      Caption = '&Archivo'
      object miSalir: TMenuItem
        Caption = '&Salir'
        ShortCut = 32883
        OnClick = miSalirClick
      end
    end
    object miMaestros: TMenuItem
      Caption = '&Maestros'
      object miOperarios: TMenuItem
        Caption = '&Operarios'
        OnClick = btnOperariosClick
      end
      object miOrdenes: TMenuItem
        Caption = #211'rdenes de Trabajo'
        OnClick = btnOrdenesClick
      end
    end
    object miPlanificacion: TMenuItem
      Caption = '&Planificaci'#243'n'
      object miPesos: TMenuItem
        Caption = 'Par'#225'metros y &Pesos'
        OnClick = btnPesosClick
      end
      object miEjecutarBatch: TMenuItem
        Caption = '&Ejecutar Batch'
        OnClick = btnEjecutarClick
      end
      object miVerAsignaciones: TMenuItem
        Caption = '&Ver Asignaciones'
        OnClick = btnAsignacionesClick
      end
    end
  end
end
