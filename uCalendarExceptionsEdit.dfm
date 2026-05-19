object frmCalendarExceptionsEdit: TfrmCalendarExceptionsEdit
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'Excepciones del calendario'
  ClientHeight = 480
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 12
      Top = 8
      Width = 211
      Height = 21
      Caption = 'Excepciones del calendario'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblCalendarNombre: TLabel
      Left = 12
      Top = 32
      Width = 200
      Height = 15
      Caption = ''
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 436
    Width = 760
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCerrar: TButton
      Left = 660
      Top = 10
      Width = 90
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Cerrar'
      Default = True
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 56
    Width = 760
    Height = 38
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object btnAdd: TButton
      Left = 12
      Top = 6
      Width = 90
      Height = 26
      Caption = 'A'#241'adir...'
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnEdit: TButton
      Left = 106
      Top = 6
      Width = 90
      Height = 26
      Caption = 'Editar...'
      TabOrder = 1
      OnClick = btnEditClick
    end
    object btnDel: TButton
      Left = 200
      Top = 6
      Width = 90
      Height = 26
      Caption = 'Eliminar'
      TabOrder = 2
      OnClick = btnDelClick
    end
  end
  object grdExcepciones: TStringGrid
    Left = 0
    Top = 94
    Width = 760
    Height = 342
    Align = alClient
    ColCount = 4
    DefaultRowHeight = 22
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect, goThumbTracking]
    TabOrder = 3
    OnDblClick = grdExcepcionesDblClick
  end
end
