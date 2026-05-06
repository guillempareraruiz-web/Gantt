object VistaKanbanForm: TVistaKanbanForm
  Left = 0
  Top = 0
  Caption = 'Vista Kanban'
  ClientHeight = 700
  ClientWidth = 1100
  Color = 16053492
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 17
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    Color = 16579836
    ParentBackground = False
    TabOrder = 0
    object lblCentro: TLabel
      Left = 12
      Top = 16
      Width = 44
      Height = 17
      Caption = 'Centro:'
    end
    object lblPrioridad: TLabel
      Left = 290
      Top = 16
      Width = 60
      Height = 17
      Caption = 'Prioridad:'
    end
    object lblArticulo: TLabel
      Left = 470
      Top = 16
      Width = 51
      Height = 17
      Caption = 'Art'#237'culo:'
    end
    object cbCentro: TComboBox
      Left = 62
      Top = 12
      Width = 220
      Height = 25
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbCentroChange
    end
    object cbPrioridad: TComboBox
      Left = 356
      Top = 12
      Width = 100
      Height = 25
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbPrioridadChange
    end
    object edArticulo: TEdit
      Left = 527
      Top = 12
      Width = 180
      Height = 25
      TabOrder = 2
      TextHint = 'C'#243'digo art'#237'culo'
      OnChange = edArticuloChange
    end
    object btnLimpiar: TButton
      Left = 715
      Top = 11
      Width = 90
      Height = 27
      Caption = 'Limpiar filtros'
      TabOrder = 3
      OnClick = btnLimpiarClick
    end
    object btnNuevaCol: TButton
      Left = 815
      Top = 11
      Width = 130
      Height = 27
      Caption = 'Nueva columna'
      TabOrder = 4
      OnClick = btnNuevaColClick
    end
    object btnRestaurar: TButton
      Left = 955
      Top = 11
      Width = 130
      Height = 27
      Caption = 'Restaurar por defecto'
      TabOrder = 5
      OnClick = btnRestaurarClick
    end
  end
  object pnlBoard: TPanel
    Left = 0
    Top = 48
    Width = 1100
    Height = 652
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 1
  end
end
