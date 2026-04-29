object frmGanttDatesDialog: TfrmGanttDatesDialog
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Rango de fechas del Gantt'
  ClientHeight = 260
  ClientWidth = 440
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
    Width = 440
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 250
      Height = 25
      Caption = 'Rango de fechas del Gantt'
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
      Caption = 'Define el periodo visible en el diagrama de Gantt'
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
    Top = 220
    Width = 440
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 228
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 332
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
    Width = 440
    Height = 160
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblFechaInicio: TLabel
      Left = 24
      Top = 24
      Width = 70
      Height = 15
      Caption = 'Fecha inicio:'
    end
    object lblFechaFin: TLabel
      Left = 24
      Top = 64
      Width = 58
      Height = 15
      Caption = 'Fecha fin:'
    end
    object lblHelp: TLabel
      Left = 24
      Top = 112
      Width = 392
      Height = 32
      AutoSize = False
      Caption =
        'El rango define el periodo visible en el Gantt. El rango debe se'+
        'r coherente con los nodos del proyecto.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object dtFechaInicio: TcxDateEdit
      Left = 160
      Top = 20
      TabOrder = 0
      Width = 150
    end
    object dtFechaFin: TcxDateEdit
      Left = 160
      Top = 60
      TabOrder = 1
      Width = 150
    end
  end
end
