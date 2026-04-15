object frmGestionDemos: TfrmGestionDemos
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Instalar datos de Demo'
  ClientHeight = 520
  ClientWidth = 640
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
    Width = 640
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
      Caption = 'Instalar Datos Demo'
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
      Caption = 'Selecciona un sector para poblar la base de datos con datos de ejemplo'
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
    Top = 480
    Width = 640
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCerrar: TButton
      Left = 536
      Top = 6
      Width = 96
      Height = 28
      Caption = 'Cerrar'
      Cancel = True
      ModalResult = 2
      TabOrder = 0
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 60
    Width = 280
    Height = 420
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 2
    object lblSectores: TLabel
      Left = 12
      Top = 8
      Width = 120
      Height = 15
      Caption = 'Sectores disponibles:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lbSectores: TListBox
      Left = 12
      Top = 30
      Width = 256
      Height = 380
      ItemHeight = 20
      TabOrder = 0
      OnClick = lbSectoresClick
    end
  end
  object pnlRight: TPanel
    Left = 280
    Top = 60
    Width = 360
    Height = 420
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object lblDetalle: TLabel
      Left = 12
      Top = 8
      Width = 100
      Height = 15
      Caption = 'Detalle del sector:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object memoDetalle: TMemo
      Left = 12
      Top = 30
      Width = 340
      Height = 280
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object btnInstalar: TButton
      Left = 12
      Top = 320
      Width = 340
      Height = 36
      Caption = 'Instalar / Reinstalar datos demo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = btnInstalarClick
    end
    object btnEliminar: TButton
      Left = 12
      Top = 362
      Width = 340
      Height = 30
      Caption = 'Eliminar datos demo'
      TabOrder = 2
      OnClick = btnEliminarClick
    end
  end
end
