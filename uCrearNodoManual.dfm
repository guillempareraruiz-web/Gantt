object frmCrearNodoManual: TfrmCrearNodoManual
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Crear nodo manual'
  ClientHeight = 470
  ClientWidth = 440
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 440
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16444380
    ParentBackground = False
    TabOrder = 0
    object lblHeaderTitle: TLabel
      Left = 16
      Top = 9
      Width = 130
      Height = 21
      Caption = 'Nuevo nodo manual'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13135400
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblHeaderSub: TLabel
      Left = 16
      Top = 32
      Width = 280
      Height = 15
      Caption = 'Tarea propia del plan, sin origen en el ERP'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13135400
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object shpHeaderLine: TShape
      Left = 0
      Top = 54
      Width = 440
      Height = 2
      Align = alBottom
      Brush.Color = 13135400
      Pen.Style = psClear
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 56
    Width = 440
    Height = 354
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 20
    Padding.Top = 14
    Padding.Right = 20
    TabOrder = 1
    object lblOperacion: TLabel
      Left = 20
      Top = 16
      Width = 80
      Height = 15
      Caption = 'Operaci'#243'n  *'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblCentro: TLabel
      Left = 20
      Top = 68
      Width = 56
      Height = 15
      Caption = 'Centro  *'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblDescripcion: TLabel
      Left = 20
      Top = 120
      Width = 130
      Height = 15
      Caption = 'Descripci'#243'n (opcional)'
    end
    object lblDuracion: TLabel
      Left = 20
      Top = 172
      Width = 75
      Height = 15
      Caption = 'Duraci'#243'n  *'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblDuracionUnit: TLabel
      Left = 132
      Top = 192
      Width = 96
      Height = 15
      Caption = 'minutos (m'#237'n. 5)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblInicio: TLabel
      Left = 240
      Top = 172
      Width = 60
      Height = 15
      Caption = 'Inicio'
    end
    object lblVinculo: TLabel
      Left = 20
      Top = 268
      Width = 119
      Height = 15
      Caption = 'V'#237'nculo ERP (opcional)'
    end
    object lblClaveERP: TLabel
      Left = 240
      Top = 268
      Width = 56
      Height = 15
      Caption = 'Clave ERP'
      Enabled = False
    end
    object cbOperacion: TComboBox
      Left = 20
      Top = 35
      Width = 400
      Height = 23
      Style = csDropDown
      TabOrder = 0
      TextHint = 'Selecciona o escribe una operaci'#243'n...'
    end
    object cbCentro: TComboBox
      Left = 20
      Top = 87
      Width = 400
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
    object edtDescripcion: TEdit
      Left = 20
      Top = 139
      Width = 400
      Height = 23
      TabOrder = 2
      TextHint = 'Si se deja vac'#237'a, se usa el nombre de la operaci'#243'n'
    end
    object seDuracion: TcxSpinEdit
      Left = 20
      Top = 189
      Properties.AssignedValues.MinValue = True
      Properties.Increment = 5.000000000000000000
      Properties.MaxValue = 100000.000000000000000000
      Properties.MinValue = 5.000000000000000000
      Properties.ValueType = vtInt
      TabOrder = 3
      Value = 30
      Width = 100
    end
    object dtpFecha: TDateTimePicker
      Left = 240
      Top = 189
      Width = 110
      Height = 23
      Date = 46022.000000000000000000
      Time = 0.500000000000000000
      TabOrder = 4
    end
    object dtpHora: TDateTimePicker
      Left = 356
      Top = 189
      Width = 64
      Height = 23
      Date = 46022.000000000000000000
      Time = 0.375000000000000000
      Kind = dtkTime
      TabOrder = 5
    end
    object chkUsaCompromiso: TCheckBox
      Left = 20
      Top = 226
      Width = 200
      Height = 17
      Caption = 'Fecha compromiso / entrega'
      TabOrder = 6
      OnClick = chkUsaCompromisoClick
    end
    object dtpCompromiso: TDateTimePicker
      Left = 240
      Top = 222
      Width = 110
      Height = 23
      Date = 46022.000000000000000000
      Time = 0.000000000000000000
      Enabled = False
      TabOrder = 7
    end
    object cbVinculo: TComboBox
      Left = 20
      Top = 287
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 8
      OnChange = cbVinculoChange
      Items.Strings = (
        'Ninguno'
        'Orden de fabricaci'#243'n (OF)'
        'Pedido'
        'Proyecto')
    end
    object edtClaveERP: TEdit
      Left = 240
      Top = 287
      Width = 180
      Height = 23
      Enabled = False
      TabOrder = 9
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 410
    Width = 440
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 2
    object btnAceptar: TButton
      Left = 232
      Top = 14
      Width = 96
      Height = 32
      Caption = 'Crear nodo'
      Default = True
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TButton
      Left = 334
      Top = 14
      Width = 90
      Height = 32
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
