object frmShiftModelEdit: TfrmShiftModelEdit
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'Modelo horario'
  ClientHeight = 560
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblNombre: TLabel
      Left = 12
      Top = 12
      Width = 47
      Height = 15
      Caption = 'Nombre:'
    end
    object lblDescripcion: TLabel
      Left = 340
      Top = 12
      Width = 74
      Height = 15
      Caption = 'Descripci'#243'n:'
    end
    object edNombre: TEdit
      Left = 80
      Top = 8
      Width = 240
      Height = 23
      TabOrder = 0
    end
    object edDescripcion: TEdit
      Left = 420
      Top = 8
      Width = 560
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
    object btnFill24: TButton
      Left = 80
      Top = 36
      Width = 120
      Height = 24
      Caption = 'Laborable 24/7'
      TabOrder = 2
      OnClick = btnFill24Click
    end
    object btnFillL_V: TButton
      Left = 206
      Top = 36
      Width = 160
      Height = 24
      Caption = 'L-V 8-13 / 14-18'
      TabOrder = 3
      OnClick = btnFillLVClick
    end
    object btnClear: TButton
      Left = 372
      Top = 36
      Width = 100
      Height = 24
      Caption = 'Limpiar todo'
      TabOrder = 4
      OnClick = btnClearClick
    end
    object lblPrecision: TLabel
      Left = 506
      Top = 41
      Width = 56
      Height = 15
      Caption = 'Precisi'#243'n:'
    end
    object cbPrecision: TComboBox
      Left = 568
      Top = 37
      Width = 90
      Height = 23
      Style = csDropDownList
      TabOrder = 5
      OnChange = cbPrecisionChange
    end
    object btnZoomOut: TButton
      Left = 680
      Top = 36
      Width = 28
      Height = 24
      Caption = '-'
      TabOrder = 6
      OnClick = btnZoomOutClick
    end
    object btnZoomFit: TButton
      Left = 710
      Top = 36
      Width = 60
      Height = 24
      Caption = 'Ajustar'
      TabOrder = 7
      OnClick = btnZoomFitClick
    end
    object btnZoomIn: TButton
      Left = 772
      Top = 36
      Width = 28
      Height = 24
      Caption = '+'
      TabOrder = 8
      OnClick = btnZoomInClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 516
    Width = 1000
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 800
      Top = 10
      Width = 90
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Guardar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 900
      Top = 10
      Width = 90
      Height = 26
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object sbHorz: TScrollBar
    Left = 0
    Top = 444
    Width = 1000
    Height = 16
    Align = alBottom
    Kind = sbHorizontal
    PageSize = 0
    TabOrder = 4
    Visible = False
    OnChange = sbHorzChange
  end
  object pnlInfo: TPanel
    Left = 0
    Top = 460
    Width = 1000
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblLeyenda: TLabel
      Left = 12
      Top = 6
      Width = 500
      Height = 16
      AutoSize = False
      Caption = 'Bot'#243'n izquierdo: pintar laborable (verde)   |   Bot'#243'n derecho: pintar no laborable (gris)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblHover: TLabel
      Left = 540
      Top = 6
      Width = 440
      Height = 16
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblKPIs: TLabel
      Left = 12
      Top = 28
      Width = 970
      Height = 22
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
  object pbGrid: TPaintBox
    Left = 0
    Top = 64
    Width = 1000
    Height = 424
    Align = alClient
    OnMouseDown = pbGridMouseDown
    OnMouseMove = pbGridMouseMove
    OnMouseUp = pbGridMouseUp
    OnPaint = pbGridPaint
  end
end
