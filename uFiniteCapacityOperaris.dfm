object frmFiniteCapacityOperaris: TfrmFiniteCapacityOperaris
  Left = 0
  Top = 0
  Caption = 'Planificaci'#243'n por operario'
  ClientHeight = 700
  ClientWidth = 1320
  Color = 15789544
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1320
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 18
      Width = 245
      Height = 21
      Caption = 'Planificaci'#243'n de carga por operario'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object cbRango: TComboBox
      Left = 320
      Top = 18
      Width = 160
      Height = 25
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbRangoChange
    end
    object cbOrden: TComboBox
      Left = 496
      Top = 18
      Width = 200
      Height = 25
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbOrdenChange
    end
    object cbFiltroOp: TComboBox
      Left = 712
      Top = 18
      Width = 200
      Height = 25
      Style = csDropDownList
      TabOrder = 2
      OnChange = cbFiltroOpChange
    end
    object chkSoloCapacitados: TCheckBox
      Left = 928
      Top = 22
      Width = 130
      Height = 17
      Caption = 'Solo capacitados'
      TabOrder = 3
      OnClick = chkSoloCapacitadosClick
    end
    object btnOperariosVisibles: TButton
      Left = 1080
      Top = 18
      Width = 160
      Height = 25
      Caption = 'Operarios visibles...'
      TabOrder = 4
      OnClick = btnOperariosVisiblesClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 656
    Width = 1320
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 1
    object lblResumen: TLabel
      Left = 16
      Top = 14
      Width = 800
      Height = 17
      Caption = 'Resumen'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnOK: TButton
      Left = 1144
      Top = 8
      Width = 80
      Height = 28
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 1232
      Top = 8
      Width = 80
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 56
    Width = 1320
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    Color = 15789544
    ParentBackground = False
    TabOrder = 2
    object splPanels: TSplitter
      Left = 280
      Top = 0
      Width = 6
      Height = 600
      Color = 14737632
      ParentColor = False
    end
    object pnlPendientes: TPanel
      Left = 0
      Top = 0
      Width = 280
      Height = 600
      Align = alLeft
      BevelOuter = bvNone
      Color = 16579836
      ParentBackground = False
      TabOrder = 0
      object pnlPendientesHeader: TPanel
        Left = 0
        Top = 0
        Width = 280
        Height = 64
        Align = alTop
        BevelOuter = bvNone
        Color = 16579836
        ParentBackground = False
        TabOrder = 0
        object lblPendientes: TLabel
          Left = 8
          Top = 6
          Width = 200
          Height = 17
          Caption = 'OTs pendientes'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 6316128
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object edFiltroArticulo: TEdit
          Left = 8
          Top = 30
          Width = 264
          Height = 25
          TabOrder = 0
          TextHint = 'Filtrar por art'#237'culo / OT...'
          OnChange = edFiltroArticuloChange
        end
      end
    end
    object pnlOperarios: TPanel
      Left = 286
      Top = 0
      Width = 1034
      Height = 600
      Align = alClient
      BevelOuter = bvNone
      Color = 16053492
      ParentBackground = False
      TabOrder = 1
    end
  end
  object pmCard: TPopupMenu
    Left = 600
    Top = 200
    object miLock: TMenuItem
      Caption = 'Bloquear / desbloquear asignaci'#243'n'
      OnClick = miLockClick
    end
    object miUnassign: TMenuItem
      Caption = 'Quitar asignaci'#243'n'
      OnClick = miUnassignClick
    end
  end
  object pmOperario: TPopupMenu
    Left = 700
    Top = 200
    object miDesasignarTodo: TMenuItem
      Caption = 'Desasignar todo del operario'
      OnClick = miDesasignarTodoClick
    end
    object miOpSep1: TMenuItem
      Caption = '-'
    end
    object miBloquearTodo: TMenuItem
      Caption = 'Bloquear todas las asignaciones'
      OnClick = miBloquearTodoClick
    end
    object miDesbloquearTodo: TMenuItem
      Caption = 'Desbloquear todas las asignaciones'
      OnClick = miDesbloquearTodoClick
    end
    object miOpSep2: TMenuItem
      Caption = '-'
    end
    object miGestionAusencias: TMenuItem
      Caption = 'Gestionar ausencias del operario...'
      OnClick = miGestionAusenciasClick
    end
    object miGestionCalendario: TMenuItem
      Caption = 'Gestionar calendario del operario...'
      OnClick = miGestionCalendarioClick
    end
  end
  object pmAbsence: TPopupMenu
    Left = 800
    Top = 200
    object miQuitarAusencia: TMenuItem
      Caption = 'Quitar ausencia'
      OnClick = miQuitarAusenciaClick
    end
  end
end
